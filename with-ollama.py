"""Run a foreground command for the lifetime of a private loopback Ollama."""
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
from contextlib import ExitStack
from http.client import HTTPConnection, HTTPException


def stop(child):
    child.terminate()
    try:
        child.wait(timeout=5)
    except subprocess.TimeoutExpired:
        child.kill()
        child.wait()


def main(ollama, *command):
    interrupted = 0

    def interrupt(signum, _frame):
        nonlocal interrupted
        interrupted = signum

    for sig in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, interrupt)

    with ExitStack() as cleanup:
        log = cleanup.enter_context(tempfile.TemporaryFile())
        env = dict(os.environ, OLLAMA_HOST='127.0.0.1:0', OLLAMA_NO_CLOUD='1', OLLAMA_NOPRUNE='1')
        server = subprocess.Popen([ollama, 'serve'], env={**env, 'OLLAMA_DEBUG': '0'},
                                  stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
        cleanup.callback(stop, server)
        # Have Ollama bind port zero itself; probing for a free port would race another launch.
        deadline = time.monotonic() + 30
        while not interrupted:
            startup = os.pread(log.fileno(), 65536, 0)
            if server.poll() is not None or time.monotonic() >= deadline:
                sys.exit('Ollama failed to start: ' + startup.decode(errors='replace').strip().split('\n')[-1])
            match = re.search(rb'Listening on (127\.0\.0\.1:\d+) ', startup)
            if match:
                host = match[1].decode()
                http = HTTPConnection(host, timeout=0.5)
                try:
                    http.request('GET', '/api/version')
                    if http.getresponse().status == 200:
                        break
                except (OSError, HTTPException):
                    pass  # The socket is bound before the HTTP handler is ready.
                finally:
                    http.close()
            time.sleep(0.05)
        if not interrupted:
            env.update(OLLAMA_HOST=host, PI_POWER_DEV_OLLAMA_URL='http://' + host)
            client = subprocess.Popen(command, env=env)  # inherit the actual terminal
            cleanup.callback(stop, client)
            while not interrupted:
                try:
                    code = client.wait(timeout=0.25)
                    return code if code >= 0 else 128 - code
                except subprocess.TimeoutExpired:
                    pass
        return 128 + interrupted


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
