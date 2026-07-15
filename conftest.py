# Test config shared across the suite.
# We put lambda/ on the path so `import common...` resolves in tests.
import sys
from pathlib import Path

LAMBDA_DIR = Path(__file__).resolve().parent.parent / "lambda"
if str(LAMBDA_DIR) not in sys.path:
    sys.path.insert(0, str(LAMBDA_DIR))
