import argparse

parser = argparse.ArgumentParser(description='Description of your program')
parser.add_argument('-f', '--foo', help='Description for foo argument', required=True)
parser.add_argument('-b', '--bar', help='Description for bar argument', required=False)

args = vars(parser.parse_args())

foo = args['foo']
bar = args['bar']

print(f'foo = {foo}')
print(f'bar = {bar}')
