import random
import argparse
import sys
import os
import re

def random_string(min_len=1, max_len=30, charset=None):
    length = random.randint(min_len, max_len)
    if charset is None:
        charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
    return ''.join(random.choice(charset) for _ in range(length))

def escape_value(value):
    # ИСПРАВЛЕНО: добавлены [] в список специальных символов
    if any(c in value for c in ' \t\n\r"\'[]'):
        quote = "'" if ('"' in value and "'" not in value) else '"'
        # Экранируем обратный слэш и выбранную кавычку
        escaped = value.replace('\\', '\\\\').replace(quote, f'\\{quote}')
        return f'{quote}{escaped}{quote}'
    return value

def generate_attributes(max_attrs=5):
    attrs = []
    for _ in range(random.randint(0, max_attrs)):
        attr_name = random_string(1, 10)
        # ИСПРАВЛЕНО: убраны [] из набора символов для значений
        # Или оставлены, но они будут экранированы
        attr_value = random_string(1, 30,
                                   "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ !@#$%^&*(){};:,./<>?|`~")
        attrs.append(f'{attr_name}={escape_value(attr_value)}')
    return ' '.join(attrs)

def generate_node(depth, max_depth, node_count):
    if depth >= max_depth or node_count[0] <= 0:
        return ''

    node_count[0] -= 1
    node_name = random_string(1, 10)
    attributes = generate_attributes()

    children = []
    child_count = random.randint(0, min(3, max_depth - depth))  # Ограничение на детей
    for _ in range(child_count):
        if node_count[0] <= 0:
            break
        child = generate_node(depth + 1, max_depth, node_count)
        if child:
            children.append(child)

    inner_content = ' '.join(filter(None, [attributes] + children))
    return f'[{node_name} {inner_content}]' if inner_content else f'[{node_name}]'

def get_next_filename():
    """Находит следующее доступное имя файла в формате test_N.conf"""
    pattern = re.compile(r'test_(\d+)\.conf$')
    existing_numbers = []

    for filename in os.listdir('.'):
        if os.path.isfile(filename):
            match = pattern.match(filename)
            if match:
                existing_numbers.append(int(match.group(1)))

    if not existing_numbers:
        return 'test_1.conf'

    existing_numbers.sort()

    for i, num in enumerate(existing_numbers, start=1):
        if num != i:
            return f'test_{i}.conf'

    return f'test_{len(existing_numbers) + 1}.conf'

def main():
    parser = argparse.ArgumentParser(description='Generate structured text files')
    parser.add_argument('num_nodes', type=int, help='Total number of nodes')
    parser.add_argument('max_depth', type=int, help='Maximum depth of tree')

    args = parser.parse_args()

    if args.num_nodes <= 0 or args.max_depth <= 0:
        print("Arguments must be positive integers")
        sys.exit(1)

    filename = get_next_filename()

    node_count = [args.num_nodes]
    result = generate_node(0, min(args.max_depth, args.num_nodes), node_count)

    with open(filename, 'w') as f:
        f.write(result)

    print(f"File generated as {filename}")

if __name__ == '__main__':
    main()