"""
common — shared utilities for all Lambda handlers.

This package exists so the 4 API handlers don't repeat boilerplate:
building API-Gateway-compatible responses, validating input, and
raising typed errors.
"""