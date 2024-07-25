print("計算普通相等吞吐量")
print("========================")
s = input('請輸入單個host的吞吐量 (s1,s2,s3...)：')   
s = list(map(float, s.split(',')))
c = input('請輸入多個host並行的吞吐量 (c1,c2,c3...)：')   
c = list(map(float, c.split(',')))

oneDsi_sum = 0
for ss in s:
    oneDsi_sum = oneDsi_sum + 1/ss

ciDsi_sum = 0
for cc,ss in zip(c,s):
    ciDsi_sum = ciDsi_sum + cc/ss

t = ciDsi_sum/oneDsi_sum

print(f'目標吞吐量為t = {t:.3f}')

