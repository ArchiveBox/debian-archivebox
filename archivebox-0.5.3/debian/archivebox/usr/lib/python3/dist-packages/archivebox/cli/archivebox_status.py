#!/usr/bin/env python3

__package__ = 'archivebox.cli'
__command__ = 'archivebox status'

import sys
import argparse

from typing import Optional, List, IO

from ..main import status
from ..util import docstring
from ..config import OUTPUT_DIR
from ..logging_util import SmartFormatter, reject_stdin


@docstring(status.__doc__)
def main(args: Optional[List[str]]=None, stdin: Optional[IO]=None, pwd: Optional[str]=None) -> None:
    parser = argparse.ArgumentParser(
        prog=__command__,
        description=status.__doc__,
        add_help=True,
        formatter_class=SmartFormatter,
    )
    parser.parse_args(args or ())
    reject_stdin(__command__, stdin)

    status(out_dir=pwd or OUTPUT_DIR)


if __name__ == '__main__':
    main(args=sys.argv[1:], stdin=sys.stdin)
