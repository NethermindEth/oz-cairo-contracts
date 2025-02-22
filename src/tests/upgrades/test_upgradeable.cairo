use openzeppelin::tests::mocks::upgrades_mocks::{
    IUpgradesV1Dispatcher, IUpgradesV1DispatcherTrait, UpgradesV1
};
use openzeppelin::tests::mocks::upgrades_mocks::{
    IUpgradesV2Dispatcher, IUpgradesV2DispatcherTrait, UpgradesV2
};
use openzeppelin::tests::utils::constants::{CLASS_HASH_ZERO, ZERO};
use openzeppelin::tests::utils::debug::DebugClassHash;
use openzeppelin::tests::utils;
use openzeppelin::upgrades::UpgradeableComponent::Upgraded;
use starknet::ClassHash;
use starknet::ContractAddress;

const VALUE: felt252 = 123;

fn V2_CLASS_HASH() -> ClassHash {
    UpgradesV2::TEST_CLASS_HASH.try_into().unwrap()
}

//
// Setup
//

fn deploy_v1() -> IUpgradesV1Dispatcher {
    let calldata = array![];
    let address = utils::deploy(UpgradesV1::TEST_CLASS_HASH, calldata);
    IUpgradesV1Dispatcher { contract_address: address }
}

//
// upgrade
//

#[test]
#[should_panic(expected: ('Class hash cannot be zero', 'ENTRYPOINT_FAILED',))]
fn test_upgrade_with_class_hash_zero() {
    let v1 = deploy_v1();
    v1.upgrade(CLASS_HASH_ZERO());
}

#[test]
fn test_upgraded_event() {
    let v1 = deploy_v1();
    v1.upgrade(V2_CLASS_HASH());

    assert_only_event_upgraded(V2_CLASS_HASH(), v1.contract_address);
}

#[test]
fn test_new_selector_after_upgrade() {
    let v1 = deploy_v1();

    v1.upgrade(V2_CLASS_HASH());
    let v2 = IUpgradesV2Dispatcher { contract_address: v1.contract_address };

    v2.set_value2(VALUE);
    assert_eq!(v2.get_value2(), VALUE);
}

#[test]
fn test_state_persists_after_upgrade() {
    let v1 = deploy_v1();
    v1.set_value(VALUE);

    v1.upgrade(V2_CLASS_HASH());
    let v2 = IUpgradesV2Dispatcher { contract_address: v1.contract_address };

    assert_eq!(v2.get_value(), VALUE);
}

#[test]
fn test_remove_selector_passes_in_v1() {
    let v1 = deploy_v1();
    v1.remove_selector();
}

#[test]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND',))]
fn test_remove_selector_fails_in_v2() {
    let v1 = deploy_v1();
    v1.upgrade(V2_CLASS_HASH());
    // We use the v1 dispatcher because remove_selector is not in v2 interface
    v1.remove_selector();
}

//
// Helpers
//

fn assert_event_upgraded(class_hash: ClassHash, contract: ContractAddress) {
    let event = utils::pop_log::<Upgraded>(contract).unwrap();
    assert!(event.class_hash == class_hash);
}

fn assert_only_event_upgraded(class_hash: ClassHash, contract: ContractAddress) {
    assert_event_upgraded(class_hash, contract);
    utils::assert_no_events_left(ZERO());
}
