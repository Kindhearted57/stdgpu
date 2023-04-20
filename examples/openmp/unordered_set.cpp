/*
 *  Copyright 2020 Patrick Stotko
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <iostream>
#include <thrust/copy.h>
#include <thrust/reduce.h>
#include <thrust/sequence.h>

#include <stdgpu/iterator.h>        // device_begin, device_end
#include <stdgpu/memory.h>          // createDeviceArray, destroyDeviceArray
#include <stdgpu/platform.h>        // STDGPU_HOST_DEVICE
#include <stdgpu/unordered_set.cuh> // stdgpu::unordered_set
#include <fstream>
#include <chrono>
#include <ctime>
struct is_odd
{
    STDGPU_HOST_DEVICE bool
    operator()(const int x) const
    {
        return true;
    }
};

void
insert_neighbors(const int* d_result, const stdgpu::index_t n, stdgpu::unordered_set<int>& set)
{
#pragma omp parallel for
    for (stdgpu::index_t i = 0; i < n; ++i)
    {
        int num = d_result[i];
        set.insert(num);
    }
}

void
remove_neighbors(const int* d_result, const stdgpu::index_t n, stdgpu::unordered_set<int> &set )
{
#pragma omp parallel for
    for(stdgpu::index_t i = 0; i < n; ++i){
        int num = d_result[i];
        set.erase(num);
    }
}
int
main()
{
    //
    // EXAMPLE DESCRIPTION
    // -------------------
    // This example demonstrates how stdgpu::unordered_set is used to compute a duplicate-free set of numbers.
    //
    std::ofstream myfile("./unordered_set.csv");
    std::vector<int> v = {100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400};
    for(int i=0; i < v.size(); i++)
    {
        const stdgpu::index_t n = v[i];
        int* d_input = createDeviceArray<int>(n);
        stdgpu::unordered_set<int> set = stdgpu::unordered_set<int>::createDeviceObject(n);
        thrust::sequence(stdgpu::device_begin(d_input), stdgpu::device_end(d_input), 1);

        // d_input : 1, 2, 3, ..., 100

        // d_result : 1, 3, 5, ..., 99
        auto start = std::chrono::system_clock::now();
        insert_neighbors(d_input, n, set);
        auto end = std::chrono::system_clock::now();
        std::chrono::duration<double> elapsed_seconds = end-start;
        myfile << v[i] << "," << elapsed_seconds.count() << "," << "insert" << "\n";
        // set : 0, 1, 2, 3, ..., 100

        auto range_set = set.device_range();
        long long sum = thrust::reduce(range_set.begin(), range_set.end(), 0, thrust::plus<int64_t>());

        long long  sum_closed_form = (long long)n * ((long long )n + 1) / 2;

        std::cout << "After insertion the set contains " << set.size() << " elements (" << n
                  << " expected) and the computed sum is " << sum << " (" << sum_closed_form << " expected)" << std::endl;

        start = std::chrono::system_clock::now();
        remove_neighbors(d_input, n, set);
        end = std::chrono::system_clock::now();
        range_set = set.device_range();
        elapsed_seconds = end-start;
        myfile << v[i] << "," << elapsed_seconds.count() << "," << "remove" << "\n";
        sum = thrust::reduce(range_set.begin(), range_set.end(), 0, thrust::plus<int>());

        sum_closed_form = n * (n + 1) / 2;

        std::cout << "After insertion the set contains " << set.size() << " elements (" << 0
                  << " expected) and the computed sum is " << sum << " (" << 0<< " expected)" << std::endl;


        destroyDeviceArray<int>(d_input);
        stdgpu::unordered_set<int>::destroyDeviceObject(set);}
    myfile.close();
}
