#include <iostream>
#include <thrust/copy.h>
#include <thrust/reduce.h>
#include <thrust/sequence.h>

#include <stdgpu/btree.cuh>
#include <stdgpu/iterator.h>
#include <stdgpu/memory.h>
#include <stdgpu/platform.h>
#include <fstream>
#include <chrono>
#include <ctime>


void
insert_neighbors(const int* b_input, const stdgpu::index_t n, stdgpu::btree<int> &btree)
{
#pragma omp parallel for
    for (stdgpu::index_t i = 0; i < n; ++i)
    {
        int num = b_input[i];
        btree.insert(num);

    }
}


void
remove_neighbors(const int* b_input, const stdgpu::index_t n, stdgpu::btree<int> &btree)
{
#pragma omp parallel for
    for (stdgpu::index_t i = 0; i < n; ++i)
    {
        int num = b_input[i];
        btree.erase(num);

    }
}


int
main()
{
    // open the file
    std::ofstream myfile("btree.csv");
    std::vector<int> v = {100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400};
    for(int i= 0; i < v.size(); i++){
        const stdgpu::index_t n = v[i];
        int * b_input = createDeviceArray<int>(n);
        // I don't understand why every number is contained 3 times, but I set it as this for now.
        stdgpu::btree<int> btree = stdgpu::btree<int>::createDeviceObject(n*3+3);
        // doc can be found here
        // https://docs.nvidia.com/cuda/thrust/

        thrust::sequence(stdgpu::device_begin(b_input), stdgpu::device_end(b_input), 1);
        auto start = std::chrono::system_clock::now();
        insert_neighbors(b_input, n, btree);
        auto end = std::chrono::system_clock::now();
        std::chrono::duration<double> elapsed_seconds = end-start;
        myfile << v[i] << "," << elapsed_seconds.count() << "," << "insert" << "\n";

        auto range_btree = btree.device_range();
        long long sum = thrust::reduce(range_btree.begin(), range_btree.end(), 0, thrust::plus<int>());
        long long sum_closed_form = (long long)n * ((long long )n + 1) / 2;

        std::cout << "The set of duplicated numbers contains " << btree.size() << " elements (" << n
                  << " expected) and the computed sum is " << sum << " (" << sum_closed_form << " expected)" << std::endl;

        start = std::chrono::system_clock::now();
        remove_neighbors(b_input, n, btree);
        end = std::chrono::system_clock::now();
        range_btree = btree.device_range();
        elapsed_seconds = end - start;
        myfile << v[i] << "," << elapsed_seconds.count() << "," << "remove" << "\n";
        sum = thrust::reduce(range_btree.begin(), range_btree.end(), 0, thrust::plus<int>());
        const int sum_closed_form2 = 0;

        std::cout << "The set of duplicated numbers contains " << btree.size() << " elements (" << 0
                  << " expected) and the computed sum is " << sum << " (" << sum_closed_form2 << " expected)" << std::endl;

        destroyDeviceArray<int>(b_input);
        stdgpu::btree<int>::destroyDeviceObject(btree);
    }
    myfile.close();
}