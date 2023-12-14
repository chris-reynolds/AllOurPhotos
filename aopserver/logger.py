import logging


class Logger:
    def __init__(self, log_file="mylog.log"):
        self.log_file = log_file
        self.logger = logging.getLogger("my_logger")
        self.logger.setLevel(logging.DEBUG)

        # Create a file handler and set the level to ERROR
        error_handler = logging.FileHandler(log_file)
        error_handler.setLevel(logging.ERROR)

        # Create a stream handler and set the level to INFO
        info_handler = logging.StreamHandler()
        info_handler.setLevel(logging.INFO)

        # Create a formatter and attach it to the handlers
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        error_handler.setFormatter(formatter)
        info_handler.setFormatter(formatter)

        # Add the handlers to the logger
        self.logger.addHandler(error_handler)
        self.logger.addHandler(info_handler)

        # overwrite singleton
        _logger = self

    def log_error(self, message):
        self.logger.error(message)

    def log_info(self, message):
        self.logger.info(message)



_logger :Logger() = Logger()

def iprint(*message):
    _logger.log_info(message)

def eprint(*message):
    _logger.log_error(message)
