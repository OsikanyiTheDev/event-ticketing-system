"""errors — typed exceptions mapped to HTTP status codes."""


class APIError(Exception):
    def __init__(self, message, status_code=400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class ValidationError(APIError):
    def __init__(self, message):
        super().__init__(message, status_code=400)


class NotFoundError(APIError):
    def __init__(self, message):
        super().__init__(message, status_code=404)


class ConflictError(APIError):
    def __init__(self, message):
        super().__init__(message, status_code=409)
