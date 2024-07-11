n = int(input("請輸入主機數量："))

# 輸入單獨吞吐量
S = []
for i in range(n):
    S.append(float(input(f"請輸入第 {i+1} 台主機的單獨吞吐量：")))

# 輸入並行吞吐量
C = []
for i in range(n):
    C.append(float(input(f"請輸入第 {i+1} 台主機的並行吞吐量：")))

# 固定第一台主機為飽和主機
k = 0

# 計算主機 k 的目標吞吐量
tk = S[k]

# 移除飽和主機後的 S 列表
S = [S[i] for i in range(n) if i != k]

# 計算其他主機的目標吞吐量
sum_C_over_S = sum(C[i] / S[i] for i in range(n))
sum_1_over_S = sum(1 / S[i] for i in range(n - 1))  #沒有k所以-1

t_other = (sum_C_over_S - 1) / sum_1_over_S

# 結果列表
t = [t_other] * n
t[k] = tk  #將飽和主機的目標吞吐量存回t[]

# 顯示結果
print("\n每台主機的目標吞吐量：")
for i in range(n):
    print(f"第 {i+1} 台主機的目標吞吐量：{t[i]:.2f}")
