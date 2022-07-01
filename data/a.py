import collections


def read_file(path, is_line):
    keys = []
    with open(path) as myfile:
        for line in myfile:
            line = line[:-1]
            if is_line:
                keys.extend(line.split(" "))
            else:
                keys.append(line)

            # print(line.split(" "))
            # break
    print(len(keys))
    counter = collections.Counter(keys)

    print("different keys:", len(counter.values()))
    bigger_one = list(filter(lambda x: x > 1, counter.values()))
    print("frequency > 1:", len(bigger_one))

    bigger_one = list(filter(lambda x: x > 5, counter.values()))
    print("frequency > 5:", len(bigger_one))
    
    bigger_one = list(filter(lambda x: x > 10, counter.values()))
    print("frequency > 10:", len(bigger_one))

    bigger_one = list(filter(lambda x: x > 20, counter.values()))
    print("frequency > 20:", len(bigger_one))

    bigger_one = list(filter(lambda x: x > 50, counter.values()))
    print("frequency > 50:", len(bigger_one))


if __name__ == "__main__":
    # file_name = "kosarak.dat.txt"
    file_name = "caida_2018_srcip.txt"
    read_file(file_name, False)
    print("\n")
    read_file(file_name, True)