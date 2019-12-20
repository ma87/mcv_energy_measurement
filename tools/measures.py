import math

def mean(a):
    sum = 0
    for i in a:
        sum += i
    return sum / len(a)

def median(a):
    sorted_a = a[:]
    sorted_a.sort()
    return sorted_a[math.ceil(len(a) / 2)]

def standard_deviation(a, mean_a):
    sum = 0
    for i in a:
        sum += (i - mean_a) ** 2
    return math.sqrt(sum / (len(a) - 1))

class Measures():
    def __init__(self, number_measures):
        self.number_measures = number_measures
        self.measure = [0.0] * number_measures
        self.median = 0.0
        self.mean = 0.0
        self.standard_deviation = 0.0

    def add_measure(self, m):
        self.measure.append(m)
        self.measure.pop(0)
        self.compute()

    def compute(self):
        self.mean = "{0:8.2f}".format(mean(self.measure))
        self.standard_deviation = "{0:8.2f}".format(standard_deviation(self.measure, float(self.mean)))
        self.median = "{0:8.2f}".format(median(self.measure))

    def __str__(self):
        return str(self.median) + "\t" + str(self.mean) + "\t" + str(self.standard_deviation) + "\t" + "{0:6.2}".format(100.0 * (float(self.standard_deviation) / float(self.mean)))

    @classmethod
    def Get_header(cls):
        return str("Median \t Mean \t Std_Dev \t% Std_Dev")


