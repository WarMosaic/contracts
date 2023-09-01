// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";

library LibUintList {
  function add(UintList storage _obj, uint _val) internal {
    if (_obj.reverseMap[_val] == 0) {
      _obj.len++;
      _obj.list[_obj.len] = _val;
      _obj.reverseMap[_val] = _obj.len;
    }
  }

  function remove(UintList storage _obj, uint _val) internal {
    uint idx = _obj.reverseMap[_val];

    if (idx > 0) {
      _obj.reverseMap[_val] = 0;

      if (idx < _obj.len) {
        // shift last item to this one's location
        uint endVal = _obj.list[_obj.len];
        _obj.reverseMap[endVal] = idx;
        _obj.list[idx] = endVal;
      }
    }
  }

  function size(UintList storage _obj) internal view returns (uint) {
    return _obj.len;
  }

  function get(UintList storage _obj, uint _index) internal view returns (uint) {
    return _obj.list[_index];
  }
}
