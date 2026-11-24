"""Run with python test-lifecycle.py /path/to/ollama from this directory."""
import os
import select
import signal
import socket
import subprocess
import sys
import tempfile
import unittest
from contextlib import ExitStack
from http.client import HTTPConnection

OLLAMA = sys.argv.pop()
PROBE = "import os; print(os.environ['OLLAMA_HOST'], flush=True); input(); raise SystemExit(7)"


class Lifecycle(unittest.TestCase):
    def test_servers_are_ready_independent_and_reaped(self):
        with tempfile.TemporaryDirectory() as home, ExitStack() as stack:
            def start():
                p = stack.enter_context(subprocess.Popen(
                    [sys.executable, 'with-ollama.py', OLLAMA, sys.executable, '-c', PROBE],
                    env={**os.environ, 'HOME': home, 'OLLAMA_MODELS': home + '/models'},
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
                ))
                stack.callback(p.terminate)
                self.assertTrue(select.select([p.stdout], [], [], 20)[0], 'startup timed out')
                host = p.stdout.readline().strip()
                self.assertRegex(host, r'^127\.0\.0\.1:\d+$')
                self.assert_ready(host)
                return p, host

            first, a = start()
            second, b = start()
            self.assertNotEqual(a, b)
            first.stdin.write('\n'); first.stdin.flush()
            self.assertEqual(first.wait(timeout=10), 7)
            self.assert_closed(a)
            self.assert_ready(b)
            second.send_signal(signal.SIGHUP)
            self.assertEqual(second.wait(timeout=10), 128 + signal.SIGHUP)
            self.assert_closed(b)

    def assert_ready(self, host):
        http = HTTPConnection(host, timeout=2)
        try:
            http.request('GET', '/api/tags')
            self.assertEqual(http.getresponse().status, 200)
        finally:
            http.close()

    def assert_closed(self, host):
        with self.assertRaises(ConnectionRefusedError):
            socket.create_connection(('127.0.0.1', int(host.split(':')[1])), timeout=1).close()


if __name__ == '__main__':
    unittest.main()
