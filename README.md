# 🏦 Bitcoin-Backed Pensions

A smart contract for long-term retirement savings on the Stacks blockchain, where employees can contribute STX tokens that are locked until retirement age. 💰

## 🌟 Features

- **Employee Registration**: Register with your age to start contributing 📝
- **Secure Contributions**: Lock STX tokens until retirement age 🔒
- **Retirement Withdrawals**: Access funds only after reaching retirement age 🎯
- **Emergency Withdrawals**: Early access with penalty (admin controlled) 🚨
- **Contribution History**: Track all contributions over time 📊
- **Admin Controls**: Contract owner can manage settings ⚙️

## 🚀 Quick Start

### Prerequisites
- Clarinet installed
- Node.js and npm/yarn
- Stacks wallet

### Installation
```bash
git clone <repository-url>
cd Bitcoin-Backed-Pensions
clarinet check
```

## 📋 Contract Functions

### Public Functions

#### `register-participant(age: uint)`
Register as a participant in the pension system
- **Parameters**: `age` - Your current age (18-100)
- **Returns**: `(ok true)` on success
- **Example**: Register a 30-year-old participant

#### `contribute(amount: uint)`
Make a contribution to your pension
- **Parameters**: `amount` - STX amount in microSTX
- **Minimum**: Default 1 STX (1,000,000 microSTX)
- **Returns**: `(ok true)` on success

#### `withdraw(amount: uint)`
Withdraw funds after reaching retirement age
- **Parameters**: `amount` - Amount to withdraw in microSTX
- **Requirements**: Must be retirement age or older
- **Returns**: `(ok true)` on success

#### `withdraw-full()`
Withdraw entire pension balance
- **Requirements**: Must be retirement age or older
- **Returns**: `(ok balance)` - amount withdrawn

#### `emergency-withdraw(amount: uint)`
Emergency withdrawal with 20% penalty
- **Parameters**: `amount` - Amount to withdraw
- **Requirements**: Emergency withdrawals must be enabled
- **Returns**: `(ok withdrawal-amount)` after penalty

### Read-Only Functions

#### `get-participant(participant: principal)`
Get participant details including balance and registration info

#### `get-participant-balance(participant: principal)`
Get current pension balance for a participant

#### `is-eligible-for-retirement(participant: principal)`
Check if participant has reached retirement age

#### `get-years-until-retirement(participant: principal)`
Calculate years remaining until retirement

#### `estimate-retirement-value(participant: principal)`
Estimate future value with 5% annual growth

#### `get-contract-stats()`
Get overall contract statistics

## 🔧 Admin Functions

### `set-minimum-contribution(new-minimum: uint)`
Update minimum contribution amount

### `set-retirement-age(new-age: uint)`
Update retirement age (50-80 years)

### `toggle-contract(enabled: bool)`
Enable/disable the contract

### `toggle-emergency-withdrawals(enabled: bool)`
Enable/disable emergency withdrawals

## 💡 Usage Examples

### 1. Register as Participant
```clarity
;; Register a 30-year-old
(contract-call? .Bitcoin-Backed-Pensions register-participant u30)
```

### 2. Make Contributions
```clarity
;; Contribute 5 STX
(contract-call? .Bitcoin-Backed-Pensions contribute u5000000)
```

### 3. Check Retirement Eligibility
```clarity
;; Check if you can retire
(contract-call? .Bitcoin-Backed-Pensions is-eligible-for-retirement 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### 4. Withdraw at Retirement
```clarity
;; Withdraw 2 STX at retirement
(contract-call? .Bitcoin-Backed-Pensions withdraw u2000000)
```

## 🛡️ Security Features

- **Age Verification**: Only ages 18-100 allowed
- **Retirement Lock**: Funds locked until retirement age
- **Owner Controls**: Critical functions restricted to contract owner
- **Emergency Controls**: Emergency functions can be disabled
- **Penalty System**: 20% penalty for early withdrawals

## 📊 Contract Constants

- **Minimum Contribution**: 1 STX (1,000,000 microSTX)
- **Default Retirement Age**: 65 years
- **Emergency Withdrawal Penalty**: 20%
- **Assumed Annual Growth**: 5% for estimates

## 🔍 Error Codes

- `u1`: Not authorized
- `u2`: Already registered
- `u3`: Not registered
- `u4`: Not retirement age
- `u5`: Insufficient balance
- `u6`: Invalid amount
- `u7`: Invalid age
- `u8`: Emergency withdrawals disabled
- `u9`: Withdrawals disabled

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## ⚠️ Disclaimer

This smart contract is for educational/demo purposes. Always conduct thorough testing and auditing before deploying to mainnet with real funds.
