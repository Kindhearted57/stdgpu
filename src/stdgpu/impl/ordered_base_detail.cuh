/*
 *  Copyright 2019 Patrick Stotko
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

#ifndef STDGPU_ORDERED_BASE_DETAIL_H
#define STDGPU_ORDERED_BASE_DETAIL_H

#include <algorithm>
#include <cmath>

#include <stdgpu/algorithm.h>
#include <stdgpu/bit.h>
#include <stdgpu/contract.h>
#include <stdgpu/functional.h>
#include <stdgpu/iterator.h>
#include <stdgpu/memory.h>
#include <stdgpu/utility.h>

namespace stdgpu::detail
{

inline index_t
expected_collisions(const index_t bucket_count, const index_t capacity)
{
    STDGPU_EXPECTS(bucket_count > 0);
    STDGPU_EXPECTS(capacity > 0);

    long double k = static_cast<long double>(bucket_count);
    long double n = static_cast<long double>(capacity);
    // NOLINTNEXTLINE(readability-magic-numbers,cppcoreguidelines-avoid-magic-numbers)
    index_t result = static_cast<index_t>(n * (1.0L - std::pow(1.0L - (1.0L / k), n - 1.0L)));

    STDGPU_ENSURES(result >= 0);

    return result;
}

inline STDGPU_HOST_DEVICE float
default_max_load_factor()
{
    return 1.0F;
}

inline STDGPU_HOST_DEVICE index_t
fibonacci_hashing(const std::size_t hash, const index_t bucket_count)
{
    index_t max_bit_width_result =
            static_cast<index_t>(bit_width<std::size_t>(static_cast<std::size_t>(bucket_count)) - 1);

    // Resulting index will always be zero, but shift by the width of std::size_t is undefined/unreliable behavior, so
    // handle this special case
    if (max_bit_width_result <= 0)
    {
        return 0;
    }

    const std::size_t dropped_bit_width =
            static_cast<std::size_t>(numeric_limits<std::size_t>::digits - max_bit_width_result);

    // Improve robustness for Multiplicative Hashing
    const std::size_t improved_hash = hash ^ (hash >> dropped_bit_width);

    // 2^64/phi, where phi is the golden ratio
    const std::size_t multiplier = 11400714819323198485LLU;

    // Multiplicative Hashing to the desired range
    index_t result = static_cast<index_t>((multiplier * improved_hash) >> dropped_bit_width);

    STDGPU_ENSURES(0 <= result);
    STDGPU_ENSURES(result < bucket_count);

    return result + 1;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::allocator_type
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::get_allocator() const noexcept
{
    return _allocator;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::begin() noexcept
{
    return _values;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::begin() const noexcept
{
    return _values;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::cbegin() const noexcept
{
    return begin();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::end() noexcept
{
    return _values + total_count();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::end() const noexcept
{
    return _values + total_count();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::cend() const noexcept
{
    return end();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class ordered_base_collect_positions
{
public:
    explicit ordered_base_collect_positions(
            const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
      : _base(base)
    {
    }

    STDGPU_DEVICE_ONLY void
    operator()(const index_t i)
    {
        if (_base.occupied(i))
        {
            index_t j = _base._range_indices_end++;
            _base._range_indices[j] = i;
        }
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
device_indexed_range<const typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::value_type>
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::device_range() const
{
    _range_indices_end.store(0);

    for_each_index(execution::device,
                   total_count(),
                   ordered_base_collect_positions<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(*this));

    return device_indexed_range<const value_type>(
            stdgpu::device_range<index_t>(_range_indices, _range_indices_end.load()),
            _values);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class offset_inside_range
{
public:
    explicit offset_inside_range(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
      : _base(base)
    {
    }

    STDGPU_HOST_DEVICE bool
    operator()(const index_t i) const
    {
        index_t linked_entry = i + _base._offsets[i];

        if (linked_entry < 0 || linked_entry >= _base.total_count())
        {
            printf("stdgpu::detail::ordered_base : Linked entry out of range : %" STDGPU_PRIINDEX
                   " -> %" STDGPU_PRIINDEX "\n",
                   i,
                   linked_entry);
            return false;
        }

        return true;
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline bool
offset_range_valid(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
{
    return transform_reduce_index(execution::device,
                                  base.total_count(),
                                  true,
                                  logical_and<>(),
                                  offset_inside_range<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(base));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class count_visits
{
public:
    count_visits(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base, int* flags)
      : _base(base)
      , _flags(flags)
    {
    }

    STDGPU_DEVICE_ONLY void
    operator()(const index_t i)
    {
        index_t linked_list = i;

        atomic_ref<int>(_flags[linked_list]).fetch_add(1);

        while (_base._offsets[linked_list] != 0)
        {
            linked_list += _base._offsets[linked_list];

            atomic_ref<int>(_flags[linked_list]).fetch_add(1);

            // Prevent potential endless loop and print warning
            if (_flags[linked_list] > 1)
            {
                printf("stdgpu::detail::ordered_base : Linked list not unique : %" STDGPU_PRIINDEX
                       " visited %d times\n",
                       linked_list,
                       _flags[linked_list]);
                return;
            }
        }
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
    int* _flags;
};

class less_equal_one
{
public:
    explicit less_equal_one(int* flags)
      : _flags(flags)
    {
    }

    STDGPU_HOST_DEVICE bool
    operator()(const index_t i) const
    {
        return _flags[i] <= 1;
    }

private:
    int* _flags;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline bool
loop_free(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
{
    int* flags = createDeviceArray<int>(base.total_count(), 0);

    for_each_index(execution::device,
                   base.bucket_count(),
                   count_visits<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(base, flags));

    bool result =
            transform_reduce_index(execution::device, base.total_count(), true, logical_and<>(), less_equal_one(flags));

    destroyDeviceArray<int>(flags);

    return result;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class value_reachable
{
public:
    explicit value_reachable(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
      : _base(base)
    {
    }

    STDGPU_DEVICE_ONLY bool
    operator()(const index_t i) const
    {
        if (_base.occupied(i))
        {
            auto block = _base._key_from_value(_base._values[i]);

            if (!_base.contains(block))
            {
                printf("stdgpu::detail::ordered_base : Unreachable entry : %" STDGPU_PRIINDEX "\n", i);
                return false;
            }
        }

        return true;
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline bool
values_reachable(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
{
    return transform_reduce_index(execution::device,
                                  base.total_count(),
                                  true,
                                  logical_and<>(),
                                  value_reachable<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(base));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class values_unique
{
public:
    explicit values_unique(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
      : _base(base)
    {
    }

    STDGPU_DEVICE_ONLY bool
    operator()(const index_t i) const
    {
        if (_base.occupied(i))
        {
            auto block = _base._key_from_value(_base._values[i]);

            auto it = _base.find(block); // NOLINT(readability-qualified-auto)
            index_t position = static_cast<index_t>(it - _base.begin());

            if (position != i)
            {
                printf("stdgpu::detail::ordered_base : Duplicate entry : Expected %" STDGPU_PRIINDEX
                       " but also found at %" STDGPU_PRIINDEX "\n",
                       i,
                       position);
                return false;
            }
        }

        return true;
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline bool
unique(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
{
    return transform_reduce_index(execution::device,
                                  base.total_count(),
                                  true,
                                  logical_and<>(),
                                  values_unique<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(base));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline bool
occupied_count_valid(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
{
    index_t size_count = base.size();
    index_t size_sum = base._occupied.count();

    return (size_count == size_sum);
}

template <typename Key,
          typename Value,
          typename KeyFromValue,
          typename Hash,
          typename KeyEqual,
typename KeySmaller,           typename Allocator,
          typename InputIt>
class insert_value
{
public:
    insert_value(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base, InputIt begin)
      : _base(base)
      , _begin(begin)
    {
    }

    STDGPU_DEVICE_ONLY void
    operator()(const index_t i)
    {
        _base.insert(*to_address(_begin + i));
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
    InputIt _begin;
};

template <typename Key,
          typename Value,
          typename KeyFromValue,
          typename Hash,
          typename KeyEqual,
typename KeySmaller,           typename Allocator,
          typename KeyIterator>
class erase_from_key
{
public:
    erase_from_key(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base, KeyIterator begin)
      : _base(base)
      , _begin(begin)
    {
    }

    STDGPU_DEVICE_ONLY void
    operator()(const index_t i)
    {
        _base.erase(*(_begin + i));
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
    KeyIterator _begin;
};

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
class destroy_values
{
public:
    explicit destroy_values(const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& base)
      : _base(base)
    {
    }

    STDGPU_DEVICE_ONLY void
    operator()(const index_t n)
    {
        if (_base.occupied(n))
        {
            allocator_traits<typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::
                                     allocator_type>::destroy(_base._allocator, &(_base._values[n]));
        }
    }

private:
    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> _base;
};


template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike>
inline STDGPU_DEVICE_ONLY pair<index_t, pair<index_t, index_t>>
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::internal_search(const KeyLike& key) const
{
    index_t key_index = total_count() / 2;
    index_t gp = -1;
    index_t p = -1;
    index_t n = -1;

    n = key_index; // root

    while (key_index >= total_count() / 2) {
//        fprintf(stderr, "[IS] key: %d\n", key_index);
        if (_key_equal(key, _internal_values[key_index - total_count() / 2]) || _key_smaller(key, _internal_values[key_index - total_count() / 2])) {
            key_index = _offsets_l[key_index];
        } else {
            key_index = _offsets_r[key_index];
        }

        gp = p;
        p = n;
        n = key_index;
    }
    fprintf(stderr, "[IS]: gp: %d, p: %d, n: %d\n", gp, p, n);

    return pair<index_t, pair<index_t, index_t>>(gp, pair<index_t, index_t>(p, n));
}


template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::bucket(const key_type& key) const
{
    return bucket_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::bucket_impl(const KeyLike& key) const
{
    index_t result = fibonacci_hashing(_hash(key), bucket_count());

    STDGPU_ENSURES(0 <= result);
    STDGPU_ENSURES(result < bucket_count());
    return result;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::bucket_size(index_t n) const
{
    STDGPU_EXPECTS(n < bucket_count());

    index_t result = 0;
    index_t key_index = n;

    // Bucket
    if (occupied(key_index))
    {
        result++;
    }

    return result;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::count(const key_type& key) const
{
    return count_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::count(const KeyLike& key) const
{
    return count_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::count_impl(const KeyLike& key) const
{
    return contains(key) ? index_t(1) : index_t(0);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find(const key_type& key)
{
    return const_cast<ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator>(
            static_cast<const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>*>(this)->find(key));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find(const key_type& key) const
{
    return find_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find(const KeyLike& key)
{
    return const_cast<ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator>(
            static_cast<const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>*>(this)->find(key));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find(const KeyLike& key) const
{
    return find_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike>
inline STDGPU_DEVICE_ONLY typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::const_iterator
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find_impl(const KeyLike& key) const
{
    auto key_index = internal_search(key)->second()->second();
    if (key_index < total_count() && _key_equal_(_values[key_index], key)) {
        return _values + key_index;
    }

    return end();

}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::contains(const key_type& key) const
{
    return contains_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike,
          STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_transparent_v<Hash>&& detail::is_transparent_v<KeyEqual>)>
inline STDGPU_DEVICE_ONLY bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::contains(const KeyLike& key) const
{
    return contains_impl(key);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyLike>
inline STDGPU_DEVICE_ONLY bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::contains_impl(const KeyLike& key) const
{
    return find(key).second().second() != end();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY
        pair<typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator, operation_status>
        ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::try_insert(
                const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::value_type& value)
{
    iterator inserted_it = end();
    operation_status status = operation_status::failed_collision;
    fprintf(stderr, "[TI]: key: %d\n", value);

    while (true) {
        key_type block = _key_from_value(value);
        auto ret = internal_search(block);
        auto index = ret.second.second;
        auto p_index = ret.second.first;

        if (index < total_count() / 2 && _key_equal(block, _values[index])) {
            fprintf(stderr, "[TI]: exist at %d\n", index);
            status = operation_status::failed_no_action_required;
            return pair<iterator, operation_status>(inserted_it, status);
        }

        // create new leaf
        index_t na_index = bucket(block) / 2;
        index_t n1_index = na_index + total_count() / 2;
        fprintf(stderr, "[TI]: na_index: %d, n1_index: %d\n", na_index, n1_index);

        // collision
        if (occupied(na_index) || occupied(n1_index)) {
            fprintf(stderr, "[TI]: occupied at %d or %d\n", na_index, n1_index);
            fprintf(stderr, "[TI]: na: %d, n1: %d\n", _values[na_index], _internal_values[na_index]);
            status = operation_status::failed_no_action_required;
            return pair<iterator, operation_status>(inserted_it, status);
        }

        // try lock
        if (_locks[p_index].try_lock()) {
            if (_locks[index].try_lock())   {
                if (_locks[n1_index].try_lock())   {
                    if (_locks[na_index].try_lock())   {
                        // everything is locked
                        fprintf(stderr, "Lock succeed\n");

                        // set the leaf node
                        allocator_traits<allocator_type>::construct(_allocator, &(_values[na_index]), block);

                        // set the internal node
                        if (_key_smaller(block, _values[index])) {
                            allocator_traits<allocator_type>::construct(_allocator, &(_internal_values[na_index]), block);
                            _offsets_l[n1_index] = na_index;
                            _offsets_r[n1_index] = index;
                        } else {
                            allocator_traits<allocator_type>::construct(_allocator, &(_internal_values[na_index]), _values[index]);
                            _offsets_r[n1_index] = na_index;
                            _offsets_l[n1_index] = index;
                        }

                        // then change the parent
                        if (_offsets_l[p_index] == index) {
                            _offsets_l[p_index] = n1_index;
                        } else {
                            _offsets_r[p_index] = n1_index;
                        }

                        // finalization, update metadata
                        ++_occupied_count;
                        _occupied.set(na_index);
                        _occupied.set(n1_index);

                        inserted_it = begin() + na_index;
                        status = operation_status::success;


                        // unlock everything
                        _locks[na_index].unlock();
                        _locks[n1_index].unlock();
                        _locks[index].unlock();
                        _locks[p_index].unlock();

                        return pair<iterator, operation_status>(inserted_it, status);

                    } else { // na failed
                        _locks[n1_index].unlock();
                        _locks[index].unlock();
                        _locks[p_index].unlock();
                    }
                } else { // n1 failed
                    _locks[index].unlock();
                    _locks[p_index].unlock();
                }
            } else { // n failed
                _locks[p_index].unlock();
            }
        } else {
            // do nothing
        } // p failed
    }
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY operation_status
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::try_erase(
        const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_type& key)
{
    operation_status status = operation_status::failed_collision;

    while (true) {
        auto ret = internal_search(key);
        auto index = ret.second.second;
        auto p_index = ret.second.first;
        auto gp_index = ret.first;

        if (index < total_count() && !_key_equal(key, _values[index])) {
            status = operation_status::failed_no_action_required;
            return status;
        }

        // check grand parent
        if (!(_key_equal(p_index, _offsets_l[gp_index]) || _key_equal(p_index, _offsets_r[gp_index]))) {
            continue;
        }

        // check parent
        if (!(_key_equal(index, _offsets_l[p_index]) || _key_equal(index, _offsets_r[p_index]))) {
            continue;
        }

        // try lock
        if (_locks[p_index].try_lock()) {
            if (_locks[index].try_lock())   {
                if (_locks[gp_index].try_lock())   {

                    // get the other children of p
                    index_t pc_index = 0;
                    if (_key_equal(_offsets_l[p_index], index)) {
                        pc_index = _offsets_r[p_index];
                    } else {
                        pc_index = _offsets_l[p_index];
                    }

                    if (_locks[pc_index].try_lock())   {
                        // everything is locked

                        // change children of gp to the other children
                        if (_key_equal(_offsets_l[p_index], index)) {
                            _offsets_l[gp_index] = pc_index;
                        } else {
                            _offsets_r[gp_index] = pc_index;
                        }

                        // finalization, update metadata
                        allocator_traits<allocator_type>::destroy(_allocator, &(_internal_values[p_index - total_count()]));
                        --_occupied_count;

                        // if has children
                        if (_occupied[_offsets_l[p_index]]) {
                            allocator_traits<allocator_type>::destroy(_allocator, &(_values[_offsets_l[p_index]]));
                            --_occupied_count;
                            _occupied.reset(_offsets_l[p_index]);
                            _offsets_l[_offsets_l[p_index]] = -1;
                            _offsets_r[_offsets_l[p_index]] = -1;
                        }

                        if (_occupied[_offsets_r[p_index]]) {
                            allocator_traits<allocator_type>::destroy(_allocator, &(_values[_offsets_r[p_index]]));
                            --_occupied_count;
                            _occupied.reset(_offsets_r[p_index]);
                            _offsets_l[_offsets_r[p_index]] = -1;
                            _offsets_r[_offsets_r[p_index]] = -1;
                        }

                        // clean itself
                        _occupied.reset(p_index);
                        _offsets_l[p_index] = -1;
                        _offsets_r[p_index] = -1;
                        status = operation_status::success;

                        // unlock everything
                        _locks[pc_index].unlock();
                        _locks[gp_index].unlock();
                        _locks[index].unlock();
                        _locks[p_index].unlock();

                        return status;

                    } else { // na failed
                        _locks[gp_index].unlock();
                        _locks[index].unlock();
                        _locks[p_index].unlock();
                    }
                } else { // n1 failed
                    _locks[index].unlock();
                    _locks[p_index].unlock();
                }
            } else { // n failed
                _locks[p_index].unlock();
            }
        } else {
            // do nothing
        } // p failed
    }
    return status;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find_linked_list_end(
        const index_t linked_list_start)
{
    return end();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::find_previous_entry_position(
        const index_t entry_position,
        const index_t linked_list_start)
{
    return end();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <class... Args>
inline STDGPU_DEVICE_ONLY
        pair<typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator, bool>
        ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::emplace(Args&&... args)
{
    return insert(value_type(forward<Args>(args)...));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY
        pair<typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::iterator, bool>
        ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::insert(
                const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::value_type& value)
{
    pair<iterator, operation_status> result(end(), operation_status::failed_collision);

    while (true)
    {
        if (result.second == operation_status::failed_collision && !full() && !_excess_list_positions.empty())
        {
            result = try_insert(value);
        }
        else
        {
            break;
        }
    }

    return result.second == operation_status::success ? pair<iterator, bool>(result.first, true)
                                                      : pair<iterator, bool>(result.first, false);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename InputIt, STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_iterator_v<InputIt>)>
inline void
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::insert(InputIt begin, InputIt end)
{
    for_each_index(execution::device,
                   static_cast<index_t>(end - begin),
                   insert_value<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator, InputIt>(*this, begin));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::erase(
        const ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_type& key)
{
    operation_status result = operation_status::failed_collision;

    while (true)
    {
        if (result == operation_status::failed_collision)
        {
            result = try_erase(key);
        }
        else
        {
            break;
        }
    }

    return result == operation_status::success ? 1 : 0;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
template <typename KeyIterator, STDGPU_DETAIL_OVERLOAD_DEFINITION_IF(detail::is_iterator_v<KeyIterator>)>
inline void
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::erase(KeyIterator begin, KeyIterator end)
{
    for_each_index(execution::device,
                   static_cast<index_t>(end - begin),
                   erase_from_key<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator, KeyIterator>(*this, begin));
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_DEVICE_ONLY bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::occupied(const index_t n) const
{
    STDGPU_EXPECTS(0 <= n);
    fprintf(stderr, "n: %d, tc: %d\n", n, total_count());
    STDGPU_EXPECTS(n < total_count());

    return _occupied[n];
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::empty() const
{
    return (size() == 0);
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::full() const
{
    return (size() == total_count());
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::size() const
{
    index_t current_size = _occupied_count.load();

    STDGPU_ENSURES(0 <= current_size);
    STDGPU_ENSURES(current_size <= total_count());
    return current_size;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::max_size() const noexcept
{
    return total_count();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::bucket_count() const
{
    return _bucket_count;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE index_t
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::total_count() const noexcept
{
    return _occupied.size();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE float
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::load_factor() const
{
    return static_cast<float>(size()) / static_cast<float>(bucket_count());
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE float
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::max_load_factor() const
{
    return default_max_load_factor();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::hasher
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::hash_function() const
{
    return _hash;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_equal
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_eq() const
{
    return _key_equal;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
inline STDGPU_HOST_DEVICE typename ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_smaller
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::key_sm() const
{
    return _key_smaller;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
bool
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::valid() const
{
    // Special case : Zero capacity is valid
    if (total_count() == 0)
    {
        return true;
    }

    return (offset_range_valid(*this) && loop_free(*this) && values_reachable(*this) && unique(*this) &&
            occupied_count_valid(*this) && _locks.valid() && _excess_list_positions.valid());
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
void
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::clear()
{
    if (empty())
    {
        return;
    }

    if (!detail::is_allocator_destroy_optimizable<Value, allocator_type>())
    {
        for_each_index(execution::device,
                       total_count(),
                       destroy_values<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>(*this));
    }

    fill(execution::device, device_begin(_offsets_l), device_end(_offsets_l), 0);
    fill(execution::device, device_begin(_offsets_r), device_end(_offsets_r), 0);

    _occupied.reset();

    _occupied_count.store(0);

    detail::vector_clear_iota<index_t, index_allocator_type>(_excess_list_positions, bucket_count());
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::createDeviceObject(const index_t& capacity,
                                                                                        const Allocator& allocator)
{
    STDGPU_EXPECTS(capacity > 0);

    // bucket count depends on default max load factor
    index_t bucket_count = static_cast<index_t>(
            bit_ceil(static_cast<std::size_t>(std::ceil(static_cast<float>(capacity) / default_max_load_factor()))));

    // excess count is estimated by the expected collision count and conservatively lowered since entries falling into
    // regular buckets are already included here
    index_t excess_count = std::max<index_t>(1, expected_collisions(bucket_count, capacity) * 2 / 3);

    index_t total_count = bucket_count + excess_count;

    ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator> result(
            bitset<bitset_default_type, bitset_allocator_type>::createDeviceObject(total_count,
                                                                                   bitset_allocator_type(allocator)),
            atomic<int, atomic_allocator_type>::createDeviceObject(atomic_allocator_type(allocator)),
            vector<index_t, index_allocator_type>::createDeviceObject(excess_count, index_allocator_type(allocator)),
            mutex_array<mutex_default_type, mutex_array_allocator_type>::createDeviceObject(
                    total_count * 2,
                    mutex_array_allocator_type(allocator)),
            atomic<int, atomic_allocator_type>::createDeviceObject(atomic_allocator_type(allocator)),
            allocator);
    result._bucket_count = bucket_count;
    result._values = detail::createUninitializedDeviceArray<value_type, allocator_type>(result._allocator, total_count);
    result._internal_values = detail::createUninitializedDeviceArray<value_type, allocator_type>(result._allocator, total_count);
    result._offsets_l = createDeviceArray<index_t, index_allocator_type>(result._index_allocator, total_count, 0);
    result._offsets_r = createDeviceArray<index_t, index_allocator_type>(result._index_allocator, total_count, 0);
    result._range_indices =
            detail::createUninitializedDeviceArray<index_t, index_allocator_type>(result._index_allocator, total_count);
    result._key_from_value = key_from_value();
    result._hash = hasher();
    result._key_equal = key_equal();
    result._key_smaller = key_smaller();

    detail::vector_clear_iota<index_t, index_allocator_type>(result._excess_list_positions, bucket_count);

    // init the tree
    allocator_traits<allocator_type>::construct(result._allocator, &(result._values[total_count - 1]), 0x3f3f3f3f);
    allocator_traits<allocator_type>::construct(result._allocator, &(result._values[0]), -0x3f3f3f3f);

    allocator_traits<allocator_type>::construct(result._allocator, &(result._internal_values[0]), -0x3f3f3f3f);
    result._offsets_l[0] = 0;
    result._offsets_r[0] = total_count - 1;

    STDGPU_ENSURES(result._excess_list_positions.full());

    return result;
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
void
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::destroyDeviceObject(
        ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>& device_object)
{
    if (!detail::is_allocator_destroy_optimizable<value_type, allocator_type>())
    {
        device_object.clear();
    }

    device_object._bucket_count = 0;
    destroyDeviceArray<index_t, index_allocator_type>(device_object._index_allocator, device_object._offsets_l);
    destroyDeviceArray<index_t, index_allocator_type>(device_object._index_allocator, device_object._offsets_r);
    detail::destroyUninitializedDeviceArray<index_t, index_allocator_type>(device_object._index_allocator,
                                                                           device_object._range_indices);
    bitset<bitset_default_type, bitset_allocator_type>::destroyDeviceObject(device_object._occupied);
    atomic<int, atomic_allocator_type>::destroyDeviceObject(device_object._occupied_count);
    mutex_array<mutex_default_type, mutex_array_allocator_type>::destroyDeviceObject(device_object._locks);
    vector<index_t, index_allocator_type>::destroyDeviceObject(device_object._excess_list_positions);
    atomic<int, atomic_allocator_type>::destroyDeviceObject(device_object._range_indices_end);
    detail::destroyUninitializedDeviceArray<value_type, allocator_type>(device_object._allocator,
                                                                        device_object._values);
    device_object._key_from_value = key_from_value();
    device_object._hash = hasher();
    device_object._key_equal = key_equal();
    device_object._key_smaller = key_smaller();
}

template <typename Key, typename Value, typename KeyFromValue, typename Hash, typename KeyEqual, typename KeySmaller, typename Allocator>
ordered_base<Key, Value, KeyFromValue, Hash, KeyEqual, KeySmaller, Allocator>::ordered_base(
        const bitset<bitset_default_type, bitset_allocator_type>& occupied,
        const atomic<int, atomic_allocator_type>& occupied_count,
        const vector<index_t, index_allocator_type>& excess_list_positions,
        const mutex_array<mutex_default_type, mutex_array_allocator_type>& locks,
        const atomic<int, atomic_allocator_type>& range_indices_end,
        const Allocator& allocator)
  : _occupied(occupied)
  , _occupied_count(occupied_count)
  , _excess_list_positions(excess_list_positions)
  , _locks(locks)
  , _range_indices_end(range_indices_end)
  , _allocator(allocator)
  , _index_allocator(allocator)
{
}

} // namespace stdgpu::detail

#endif // STDGPU_ORDERED_BASE_DETAIL_H
