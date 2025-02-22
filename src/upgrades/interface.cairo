// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.8.1 (upgrades/interface.cairo)

use starknet::ClassHash;

#[starknet::interface]
trait IUpgradeable<TState> {
    fn upgrade(ref self: TState, new_class_hash: ClassHash);
}
