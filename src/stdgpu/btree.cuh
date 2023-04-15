#ifndef STDGPU_BTREE_H
#define STDGPU_BTREE_H

#include <stdgpu/impl/platform_check.h>

#include <stdgpu/atomic.cuh>
#include <stdgpu/bitset.cuh>
#include <stdgpu/cstddef.h>
#include <stdgpu/iterator.h>
#include <stdgpu/memory.h>
#include <stdgpu/mutex.cuh>
#include <stdgpu/platform.h>
#include <stdgpu/ranges.h>
#include <stdgpu/utility.h>

namespace stdgpu
{

template <typename T, typename Allocator = safe_device_allocator<T>>
class btree
{
public:
    using value_type = T; /**< T */

    using allocator_type = Allocator; /**< Allocator */

    using index_type = index_t;             /**< index_t */
    using difference_type = std::ptrdiff_t; /**< std::ptrdiff_t */

    using reference = value_type&;             /**< value_type& */
    using const_reference = const value_type&; /**< const value_type& */
    using pointer = value_type*;               /**< value_type* */
    using const_pointer = const value_type*;   /**< const value_type* */

    static deque<T, Allocator>
    createDeviceObject(const index_t& capacity, const Allocator& allocator = Allocator());

    static void
    destroyDeviceObject(deque<T, Allocator>& device_object);       

    deque() noexcept = default;

    STDGPU_HOST_DEVICE allocator_type
    get_allocator() const noexcept;    

    STDGPU_DEVICE_ONLY reference
    at(const index_type n);

    STDGPU_DEVICE_ONLY const_reference
    at(const index_type n) const;

    STDGPU_DEVICE_ONLY reference
    operator[](const index_type n);

    STDGPU_DEVICE_ONLY const_reference
    operator[](const index_type n) const;        
    
    STDGPU_DEVICE_ONLY reference
    front();    

    STDGPU_DEVICE_ONLY const_reference
    front() const;

    STDGPU_DEVICE_ONLY reference
    back();

    STDGPU_DEVICE_ONLY const_reference
    back() const;    
}
}