import struct
import random

# ================= 配置区 =================
# 输入：原始 SIFT query 向量文件 (如果没有，设为 None，脚本会自动生成随机向量)
INPUT_FVECS = '/home/lichengqi/sift/sift_query.fvecs' 
# INPUT_FVECS = None  # <--- 如果没有原始文件，取消这行的注释

# 输出文件路径 (覆盖错误的文件)
OUTPUT_CSV = '/home/lichengqi/sift/sift_query.csv'

ROW_COUNT = 10000  # 通常 query 是 1万条
DIM = 128          # SIFT 维度
# ==========================================

def read_fvecs(filename):
    with open(filename, 'rb') as f:
        while True:
            chunk = f.read(4)
            if not chunk: break
            dim = struct.unpack('i', chunk)[0]
            vec_bytes = f.read(4 * dim)
            vec = struct.unpack('f' * dim, vec_bytes)
            yield vec

def main():
    print(f"开始生成 {OUTPUT_CSV} (仅 ID 和 Vector)...")
    
    mode = "REAL" if INPUT_FVECS else "FAKE"
    try:
        if mode == "REAL":
            print(f"模式: 读取原始文件 {INPUT_FVECS}")
            data_source = read_fvecs(INPUT_FVECS)
        else:
            print(f"模式: 生成随机向量")
            data_source = ([random.random() * 100 for _ in range(DIM)] for _ in range(ROW_COUNT))

        with open(OUTPUT_CSV, 'w', encoding='utf-8') as f:
            count = 0
            for vec in data_source:
                # 格式化向量字符串
                vec_str = "[" + ",".join(f"{x:.6f}" for x in vec) + "]"
                
                # 写入 CSV: 只有 ID 和 Vector
                # 注意：这里千万不要加 category 或 price
                line = f'{count},"{vec_str}"\n'
                f.write(line)
                
                count += 1
                if mode == "FAKE" and count >= ROW_COUNT:
                    break
                    
        print(f"完成！共生成 {count} 行。")
        print(f"文件结构校验: id, \"[vector...]\" (共2列)")

    except FileNotFoundError:
        print(f"错误: 找不到输入文件 {INPUT_FVECS}，请检查路径或改为 None 使用随机模式。")

if __name__ == "__main__":
    main()