#include <iostream>
#include <thrust/copy.h>
#include <thrust/reduce.h>
#include <thrust/sequence.h>

#include <stdgpu/btree.cuh>
#include <stdgpu/iterator.h>
#include <stdgpu/memory.h>
#include <stdgpu/platform.h>


void
insert_neighbors(const int* b_input, const stdgpu::index_t n, stdgpu::btree<int> &btree)
{
#pragma omp parallel for
    for (stdgpu::index_t i = 0; i < n; ++i)
    {
        int num = b_input[i];
        int num_neighborhood[3] = { num - 1, num, num + 1};
        for (int num_neighbor: num_neighborhood){
            // dump everythin into the tree
            btree.insert()
        }
    }
}
int
main()
{
    const stdgpu::index_t n = 100;
    int * b_input = createDeviceArray<int>(n);
    // I don't understand why every number is contained 3 times, but I set it as this for now.
    stdgpu::btree<int> btree = stdgpu::btree<int>::createDeviceObject(3*n);
    // doc can be found here
    // https://docs.nvidia.com/cuda/thrust/

    thrust::sequence(stdgpu::device_begin(b_input), stdgpu::device_end(b_input), 1);
    
    insert_neighbors(b_input, n, btree);

    auto range_btree = btree.device_range();
    int sum = thrust::reduce(range_btree.begin(), range_btree.end(), 0, thrust:plus<int>());
    const int sum_closed_form = 3 * (n * (n + 1) / 2);

    std::cout << "The set of duplicated numbers contains " << deq.size() << " elements (" << 3 * n
              << " expected) and the computed sum is " << sum << " (" << sum_closed_form << " expected)" << std::endl;

    destroyDeviceArray<int>(d_input);
    stdgpu::btree<int>::destroyDeviceObject(btree);   
}