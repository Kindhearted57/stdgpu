#ifndef STDGPU_BTREE_DETAIL_H
#define STDGPU_BTREE_DETAIL_H


#include <utility>

#include <stdgpu/bit.h>
#include <stdgpu/contract.h>
#include <stdgpu/utility.h>

namespace stdgpu
{

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::allocator_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::get_allocator() const noexcept
{
    return _base.get_allocator();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::begin() noexcept
{
    return _base.begin();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::begin() const noexcept
{
    return _base.begin();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::cbegin() const noexcept
{
    return _base.cbegin();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::end() noexcept
{
    return _base.end();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::end() const noexcept
{
    return _base.end();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::cend() const noexcept
{
    return _base.cend();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
device_indexed_range<const typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::value_type>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::device_range() const
{
    return _base.device_range();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::index_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::bucket(const key_type& key) const
{
    return _base.bucket(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::index_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::bucket_size(index_type n) const
{
    return _base.bucket_size(n);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::index_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::count(const key_type& key) const
{
    return _base.count(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::index_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::count(const KeyLike& key) const
{
    return _base.count(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::find(const key_type& key)
{
    return _base.find(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::find(const key_type& key) const
{
    return _base.find(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::find(const KeyLike& key)
{
    return _base.find(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::find(const KeyLike& key) const
{
    return _base.find(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY bool
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::contains(const key_type& key) const
{
    return _base.contains(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY bool
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::contains(const KeyLike& key) const
{
    return _base.contains(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <class... Args>
inline STDGPU_DEVICE_ONLY pair<typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator, bool>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::emplace(Args&&... args)
{
    return _base.emplace(forward<Args>(args)...);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY pair<typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::iterator, bool>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::insert(
        const btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::value_type& value)
{
    return _base.insert(value);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename ValueIterator, STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_iterator_v<ValueIterator>)>
inline void
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::insert(ValueIterator begin, ValueIterator end)
{
    _base.insert(begin, end);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::index_type
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::erase(const btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::key_type& key)
{
    return _base.erase(key);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
template <typename KeyIterator, STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_iterator_v<KeyIterator>)>
inline void
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::erase(KeyIterator begin, KeyIterator end)
{
    _base.erase(begin, end);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE bool
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::empty() const
{
    return _base.empty();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE bool
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::full() const
{
    return _base.full();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::size() const
{
    return _base.size();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::max_size() const noexcept
{
    return _base.max_size();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::bucket_count() const
{
    return _base.bucket_count();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE float
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::load_factor() const
{
    return _base.load_factor();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE float
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::max_load_factor() const
{
    return _base.max_load_factor();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::hasher
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::hash_function() const
{
    return _base.hash_function();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::key_equal
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::key_eq() const
{
    return _base.key_eq();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::key_smaller
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::key_sm() const
{
    return _base.key_sm();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
bool
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::valid() const
{
    return _base.valid();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
void
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::clear()
{
    _base.clear();
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::createDeviceObject(const index_t& capacity, const Allocator& allocator)
{
    STDGPU_EXPECTS(capacity > 0);

    btree<Key, Hash, KeyEqual, KeySmaller, Allocator> result(base_type::createDeviceObject(capacity, allocator));

    return result;
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
void
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::destroyDeviceObject(
        btree& device_object)
{
    base_type::destroyDeviceObject(device_object._base);
}

template <typename Key, typename Hash, typename KeyEqual,
          typename KeySmaller, typename Allocator>
btree<Key, Hash, KeyEqual, KeySmaller, Allocator>::btree(base_type&& base)
  : _base(std::move(base))
{
}

} // namespace stdgpu


#endif // STDGPU_BTREE_DETAIL_H