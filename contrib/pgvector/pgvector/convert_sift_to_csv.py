import struct
import random

# ================= 配置区 =================
# 输入：原始 SIFT base 向量文件 (如果没有，设为 None，脚本会自动生成随机向量)
INPUT_FVECS = '/home/lichengqi/sift/sift_query.fvecs' 
# INPUT_FVECS = None  # <--- 如果没有原始文件，取消这行的注释

# 输出文件路径
OUTPUT_CSV = '/home/lichengqi/sift/sift_query.csv'

# 数据量 (如果使用真实文件，这个数字会被真实行数覆盖)
ROW_COUNT = 10000  # 测试用，建议先生成少量的跑通流程
DIM = 128          # SIFT 维度

# 模拟业务数据的范围
CATEGORY_RANGE = (1, 10)   # category: 1 到 10
PRICE_RANGE = (10, 1000)   # price: 10 到 1000
# ==========================================

def read_fvecs(filename):
    """读取 fvecs 格式的生成器"""
    with open(filename, 'rb') as f:
        while True:
            chunk = f.read(4)
            if not chunk: break
            dim = struct.unpack('i', chunk)[0]
            vec_bytes = f.read(4 * dim)
            vec = struct.unpack('f' * dim, vec_bytes)
            yield vec

def main():
    print(f"开始生成 {OUTPUT_CSV} ...")
    
    mode = "REAL" if INPUT_FVECS else "FAKE"
    if mode == "REAL":
        print(f"模式: 读取原始文件 {INPUT_FVECS}")
        data_source = read_fvecs(INPUT_FVECS)
    else:
        print(f"模式: 生成随机向量 (用于测试)")
        # 创建一个无限生成器
        data_source = ([random.random() * 100 for _ in range(DIM)] for _ in range(ROW_COUNT))

    try:
        with open(OUTPUT_CSV, 'w', encoding='utf-8') as f:
            count = 0
            for vec in data_source:
                # 1. 生成模拟的业务字段
                category = random.randint(*CATEGORY_RANGE)
                price = random.randint(*PRICE_RANGE)
                
                # 2. 格式化向量字符串 (注意加上双引号以防 CSV 解析错误)
                vec_str = "[" + ",".join(f"{x:.6f}" for x in vec) + "]"
                
                # 3. 写入 CSV: id, category, price, vector
                # 注意这里的顺序必须和你的 COPY 命令一致
                line = f'{count},{category},{price},"{vec_str}"\n'
                f.write(line)
                
                count += 1
                if count % 10000 == 0:
                    print(f"已处理 {count} 行...")
                
                # 如果是随机模式，达到目标行数就停止
                if mode == "FAKE" and count >= ROW_COUNT:
                    break
                    
        print(f"完成！共生成 {count} 行。")
        print(f"文件结构: id, category, price, \"[vector...]\"")

    except FileNotFoundError:
        print(f"错误: 找不到输入文件 {INPUT_FVECS}")

if __name__ == "__main__":
    main()