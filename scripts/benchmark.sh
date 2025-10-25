#!/bin/bash

set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BUILD_DIR="build"
PARSER_BIN="${BUILD_DIR}/src/parser/parser"
TEST_DATA_DIR="src/parser/test_data"
RESULTS_DIR="benchmark_results"


mkdir -p "${RESULTS_DIR}"

echo "=========================================="
echo "       PARSER BENCHMARK SUITE"
echo "=========================================="
echo ""


if [ ! -f "${PARSER_BIN}" ]; then
    echo -e "${RED}Error: Parser binary not found. Run 'make build_release' first.${NC}"
    exit 1
fi


echo -e "${YELLOW}Generating benchmark test data...${NC}"
cd "${TEST_DATA_DIR}"


rm -f bench_*.conf


python3 data_gen.py 10 3
python3 data_gen.py 100 5
python3 data_gen.py 500 7
python3 data_gen.py 1000 10


mv test_1.conf bench_small.conf 2>/dev/null || true
mv test_2.conf bench_medium.conf 2>/dev/null || true
mv test_3.conf bench_large.conf 2>/dev/null || true
mv test_4.conf bench_xlarge.conf 2>/dev/null || true

cd - > /dev/null

echo -e "${GREEN}✓ Test data generated${NC}"
echo ""


run_benchmark() {
    local testfile=$1
    local testname=$(basename "$testfile" .conf)
    local iterations=10

    echo "=========================================="
    echo "Benchmarking: ${testname}"
    echo "=========================================="


    local nodes=$(grep -o '\[' "$testfile" | wc -l)
    echo "Nodes in file: ${nodes}"


    echo "Running ${iterations} iterations..."
    local total_time=0

    for i in $(seq 1 $iterations); do
        local start=$(date +%s%N)
        "${PARSER_BIN}" "$testfile" > /dev/null 2>&1
        local end=$(date +%s%N)
        local elapsed=$((end - start))
        total_time=$((total_time + elapsed))
        printf "."
    done
    echo ""

    local avg_time=$((total_time / iterations / 1000000))
    echo -e "${GREEN}Average time: ${avg_time} ms${NC}"


    echo "${testname},${nodes},${avg_time}" >> "${RESULTS_DIR}/benchmark.csv"


    echo "Running memory profiling..."
    valgrind --tool=massif --massif-out-file="${RESULTS_DIR}/${testname}_massif.out" \
        "${PARSER_BIN}" "$testfile" > /dev/null 2>&1


    local peak_mem=$(grep mem_heap_B "${RESULTS_DIR}/${testname}_massif.out" | \
                     sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -n 1)
    local peak_mem_kb=$((peak_mem / 1024))
    echo -e "${GREEN}Peak memory: ${peak_mem_kb} KB${NC}"


    if command -v valgrind >/dev/null 2>&1; then
        echo "Running cache profiling..."
        valgrind --tool=cachegrind --cachegrind-out-file="${RESULTS_DIR}/${testname}_cachegrind.out" \
            "${PARSER_BIN}" "$testfile" > /dev/null 2>&1


        local cache_stats=$(cg_annotate "${RESULTS_DIR}/${testname}_cachegrind.out" 2>/dev/null | \
                           grep -A 1 "PROGRAM TOTALS" | tail -n 1 || echo "N/A")
        echo "Cache stats: ${cache_stats}"
    fi

    echo ""
}


echo "Test,Nodes,AvgTime_ms" > "${RESULTS_DIR}/benchmark.csv"


for testfile in "${TEST_DATA_DIR}"/bench_*.conf; do
    if [ -f "$testfile" ]; then
        run_benchmark "$testfile"
    fi
done


echo "=========================================="
echo "       BENCHMARK SUMMARY"
echo "=========================================="
cat "${RESULTS_DIR}/benchmark.csv"
echo ""


if command -v gnuplot >/dev/null 2>&1; then
    echo "Generating performance graph..."
    gnuplot << EOF
set terminal png size 800,600
set output '${RESULTS_DIR}/benchmark.png'
set title 'Parser Performance'
set xlabel 'Number of Nodes'
set ylabel 'Time (ms)'
set grid
set datafile separator ','
plot '${RESULTS_DIR}/benchmark.csv' using 2:3 with linespoints title 'Parsing Time'
EOF
    echo -e "${GREEN}✓ Graph saved to ${RESULTS_DIR}/benchmark.png${NC}"
fi

echo -e "${GREEN}✓ Benchmark complete. Results in ${RESULTS_DIR}/${NC}"