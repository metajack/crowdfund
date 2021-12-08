module Crowdfund::Crowdfund {
    use Std::Errors;
    use Std::Signer;
    use Std::Vector;

    use DiemFramework::Diem::Diem;

    const EALREADY_HAS_PROJECT: u64 = 0;
    const EMISSING_PROJECT: u64 = 1;
    const EALREADY_HAS_PLEDGE: u64 = 0;
    const EMISSING_PLEDGE: u64 = 1;

    // creator creates a dummy struct Foo which is the parameter for Project<T> and Pledge<T>
    struct Project<phantom T, phantom CoinType> has key {
        // TODO: reward_tiers,
        end_timestamp: u64,
        goal: u64,
        pledgers: vector<address>,
    }

    struct Pledge<phantom T, phantom CoinType> has key {
        project_address: address,
        amount: Diem<CoinType>,
        // TODO: chosen reward
    }

    /// Create a new crowdfund project. The phantom T is a creator provided empty struct.
    public fun create_project<T: drop, CoinType>(creator: signer, goal: u64, end_timestamp: u64, _witness: T) {
        assert!(!exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::already_published(EALREADY_HAS_PROJECT));
        move_to(&creator, Project<T, CoinType> {
            end_timestamp: end_timestamp,
            goal: goal,
            pledgers: Vector::empty(),
        });
    }

    /// Cancel a crowdfund project. Projects can only be canceled before they end.
    public(script) fun cancel_project<T, CoinType>(creator: signer, _reason: vector<u8>) acquires Project {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::not_published(EMISSING_PROJECT));
        let Project { end_timestamp: _, goal: _, pledgers: _ } = move_from<Project<T, CoinType>>(Signer::address_of(&creator));
    }

    /// Claim funds from a funded, ended project.
    public(script) fun claim_project<T, CoinType>(creator: signer) acquires Project {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::not_published(EMISSING_PROJECT));
        let Project { end_timestamp: _, goal: _, pledgers: _ } = move_from<Project<T, CoinType>>(Signer::address_of(&creator));
    }

    public(script) fun pledge<T, CoinType>(pledger: signer, project_address: address, amount: u64) {
        assert!(exists<Project<T, CoinType>>(project_address), Errors::not_published(EMISSING_PROJECT));
        assert!(!exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::already_published(EALREADY_HAS_PLEDGE));

        // let account_balance = borrow_global_mut<Balance<CoinType>>(Signer::address_of(&pledger));

        // let pledge_amount =
        // let pledge = Pledge<T, CoinType> {
        //     project_address: project_address,
        //     amount: pledge_amount,
        // };

    }

    public(script) fun cancel_pledge<T, CoinType>(pledger: signer) { 
        assert!(exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::not_published(EMISSING_PLEDGE));

    }
}
