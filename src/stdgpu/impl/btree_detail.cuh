#ifndef STDGPU_BTREE_DETAIL_H
#define STDGPU_BTREE_DETAIL_H

#include <stdgpu/contract.h>
#include <stdgpu/iterator.h>
#include <stdgpu/memory.h>
#include <stdgpu/numeric.h>
#include <stdgpu/utility.h>

namespace stdgpu
{
template <typename T, typename Allocator>
deque<T, Allocator>
deque<T, Allocator>::createDeviceObject(const index_t& capacity, const Allocator& allocator)
{
    STDGPU_EXPECTS(capacity > 0);

    deque<T, Allocator> result(
            mutex_array<mutex_default_type, mutex_array_allocator_type>::createDeviceObject(
                    capacity,
                    mutex_array_allocator_type(allocator)),
            bitset<bitset_default_type, bitset_allocator_type>::createDeviceObject(capacity,
                                                                                   bitset_allocator_type(allocator)),
            atomic<int, atomic_int_allocator_type>::createDeviceObject(atomic_int_allocator_type(allocator)),
            atomic<unsigned int, atomic_uint_allocator_type>::createDeviceObject(atomic_uint_allocator_type(allocator)),
            atomic<unsigned int, atomic_uint_allocator_type>::createDeviceObject(atomic_uint_allocator_type(allocator)),
            allocator);
    result._data = detail::createUninitializedDeviceArray<T, allocator_type>(result._allocator, capacity);
    result._range_indices =
            detail::createUninitializedDeviceArray<index_t, index_allocator_type>(result._index_allocator, capacity);

    return result;
}

template <typename T, typename Allocator>
void
deque<T, Allocator>::destroyDeviceObject(deque<T, Allocator>& device_object)
{
    if (!detail::is_allocator_destroy_optimizable<value_type, allocator_type>())
    {
        device_object.clear();
    }

    detail::destroyUninitializedDeviceArray<T, allocator_type>(device_object._allocator, device_object._data);
    detail::destroyUninitializedDeviceArray<index_t, index_allocator_type>(device_object._index_allocator,
                                                                           device_object._range_indices);
    mutex_array<mutex_default_type, mutex_array_allocator_type>::destroyDeviceObject(device_object._locks);
    bitset<bitset_default_type, bitset_allocator_type>::destroyDeviceObject(device_object._occupied);
    atomic<int, atomic_int_allocator_type>::destroyDeviceObject(device_object._size);
    atomic<unsigned int, atomic_uint_allocator_type>::destroyDeviceObject(device_object._begin);
    atomic<unsigned int, atomic_uint_allocator_type>::destroyDeviceObject(device_object._end);
}

template <typename T, typename Allocator>
inline deque<T, Allocator>::deque(const mutex_array<mutex_default_type, mutex_array_allocator_type>& locks,
                                  const bitset<bitset_default_type, bitset_allocator_type>& occupied,
                                  const atomic<int, atomic_int_allocator_type>& size,
                                  const atomic<int, atomic_int_allocator_type>& root,
                                  const Allocator& allocator)
  : _locks(locks)
  , _occupied(occupied)
  , _size(size)
  , _root(root)
  , _allocator(allocator)
  , _index_allocator(allocator)
{
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<T, Allocator>::allocator_type
btree<T, Allocator>::get_allocator() const noexcept
{
    return _allocator;
}

namespace detail
{

template <typename T, typename Allocator, typename ValueInterator, bool update_occupancy>
class btree_insert
{
public:
    btree_insert(const btree<T, Allocator> &v,
    ValueIterator values)
      : _b(b)
      , _values(value)
    {
    }
private:
    btree<T, Allocator> _b;
    ValueIterator _values;
};

template <typename T, typename Allocator, bool update_occupancy>
class btree_erase
{
public:
    btree_erase(const btree<T, Allocator>& b)
}
} // namespace detail

template <typename T, typename Allocator>
template <typename ValueIterator, STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_iterator_v<ValueIterator>)>
inline void 
vector<T, Allocator>::insert(device_ptr<const T> position, ValueIterator begin, ValueIterator end)
{
    if(position != device_end())
    {
        printf("stdgpu::btree::insert : Position not equal to device_end()\n");
        return;
    }
    
    index_t N = static_cast<index_t>(end - begin);
    index_t new_size = size() + N;
    if(new_size > capacity())
    {
        printf("stdgpu::btree::insert: Unable to insert all values: New size %" STDGPU_PRIINDEX "would exceed capacity %" STDGPU_PRIINDEX "\n",
        new_size,
        capacity());
        return;
    }

    for_each_index(execution::device,
                   N,
                   detail::vector_insert<T, Allocator,
                   ValueIterator, true>(*this, size(), begin));
    _size.store(new_size);               
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE bool
vector<T, Allocator>::empty() const
{
    return (size() == 0);
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE bool
vector<T, Allocator>::full() const
{
    return (size() == max_size());
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
vector<T, Allocator>::size() const
{
    index_t current_size = _size.load();

    // Check boundary cases where the push/pop caused the pointers to be overful/underful
    if (current_size < 0)
    {
        printf("stdgpu::vector::size : Size out of bounds: %" STDGPU_PRIINDEX " not in [0, %" STDGPU_PRIINDEX
               "]. Clamping to 0\n",
               current_size,
               capacity());
        return 0;
    }
    if (current_size > capacity())
    {
        printf("stdgpu::vector::size : Size out of bounds: %" STDGPU_PRIINDEX " not in [0, %" STDGPU_PRIINDEX
               "]. Clamping to %" STDGPU_PRIINDEX "\n",
               current_size,
               capacity(),
               capacity());
        return capacity();
    }

    STDGPU_ENSURES(current_size <= capacity());
    return current_size;
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
vector<T, Allocator>::max_size() const noexcept
{
    return capacity();
}

template <typename T, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
vector<T, Allocator>::capacity() const noexcept
{
    return _occupied.size();
}

template <typename T, typename Allocator>
inline void
vector<T, Allocator>::shrink_to_fit()
{
    // Reject request for performance reasons
}

template <typename T, typename Allocator>
inline const T*
vector<T, Allocator>::data() const noexcept
{
    return _data;
}

template <typename T, typename Allocator>
inline T*
vector<T, Allocator>::data() noexcept
{
    return _data;
}

template <typename T, typename Allocator>
inline void
vector<T, Allocator>::clear()
{
    if (empty())
    {
        return;
    }

    if (!detail::is_allocator_destroy_optimizable<value_type, allocator_type>())
    {
        const index_t current_size = size();

        detail::unoptimized_destroy(execution::device,
                                    stdgpu::device_begin(_data),
                                    stdgpu::device_begin(_data) + current_size);
    }

    _occupied.reset();

    _size.store(0);

    STDGPU_ENSURES(empty());
    STDGPU_ENSURES(valid());
}

template <typename T, typename Allocator>
inline bool
vector<T, Allocator>::valid() const
{
    // Special case : Zero capacity is valid
    if (capacity() == 0)
    {
        return true;
    }

    return (size_valid() && occupied_count_valid() && _locks.valid());
}

template <typename T, typename Allocator>
device_ptr<T>
vector<T, Allocator>::device_begin()
{
    return stdgpu::device_begin(_data);
}

template <typename T, typename Allocator>
device_ptr<T>
vector<T, Allocator>::device_end()
{
    return device_begin() + size();
}

template <typename T, typename Allocator>
device_ptr<const T>
vector<T, Allocator>::device_begin() const
{
    return stdgpu::device_begin(_data);
}

template <typename T, typename Allocator>
device_ptr<const T>
vector<T, Allocator>::device_end() const
{
    return device_begin() + size();
}

template <typename T, typename Allocator>
device_ptr<const T>
vector<T, Allocator>::device_cbegin() const
{
    return stdgpu::device_cbegin(_data);
}

template <typename T, typename Allocator>
device_ptr<const T>
vector<T, Allocator>::device_cend() const
{
    return device_cbegin() + size();
}

template <typename T, typename Allocator>
stdgpu::device_range<T>
vector<T, Allocator>::device_range()
{
    return stdgpu::device_range<T>(_data, size());
}

template <typename T, typename Allocator>
stdgpu::device_range<const T>
vector<T, Allocator>::device_range() const
{
    return stdgpu::device_range<const T>(_data, size());
}

template <typename T, typename Allocator>
inline STDGPU_DEVICE_ONLY bool
vector<T, Allocator>::occupied(const index_t n) const
{
    STDGPU_EXPECTS(0 <= n);
    STDGPU_EXPECTS(n < capacity());

    return _occupied[n];
}

template <typename T, typename Allocator>
bool
vector<T, Allocator>::occupied_count_valid() const
{
    index_t size_count = size();
    index_t size_sum = _occupied.count();

    return (size_count == size_sum);
}

template <typename T, typename Allocator>
bool
vector<T, Allocator>::size_valid() const
{
    int current_size = _size.load();
    return (0 <= current_size && current_size <= static_cast<int>(capacity()));
}

} // namespace stdgpu

#endif // STDGPU_BTREE_DETAIL_H