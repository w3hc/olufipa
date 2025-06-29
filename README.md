# Olufipa

Onchain International Law Enforcement System.

## Motivation 

International law is apparently broken. Countries routinely ignore treaties, commit war crimes, and face zero consequences. 

## Workflow

1. **Countries deposit funds** to participate in the system
2. **Violations are reported** by participating nations with evidence
3. **Kleros jurors decide** if violations occurred 
4. **Smart contracts automatically** apply penalties and distribute funds

## Install

```bash
# Clone and build
git clone <repo>
cd olufipa
forge build
```

## Test

```bash
# Run tests
forge test
```

## Deploy

```bash
# Deploy locally
anvil # (separate terminal)
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

## Key Features

- **Automated penalties** based on violation severity
- **Escalating punishments** for repeat offenders  
- **Transparent fund distribution**: 40% victims, 30% peacekeeping, 20% monitoring, 10% jurors
- **Compliance scoring** system
- **Decentralized arbitration** via Kleros integration

## Architecture

```
Countries → Deposit Funds → Report Violations → Kleros Decides → Auto-Execute Penalties
```

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) on [Farcaster](https://warpcast.com/julien-),
[Element](https://matrix.to/#/@julienbrg:matrix.org),
[Status](https://status.app/u/iwSACggKBkp1bGllbgM=#zQ3shmh1sbvE6qrGotuyNQB22XU5jTrZ2HFC8bA56d5kTS2fy),
[Telegram](https://t.me/julienbrg), [Twitter](https://twitter.com/julienbrg),
[Discord](https://discordapp.com/users/julienbrg), or [LinkedIn](https://www.linkedin.com/in/julienberanger/).

## License

This project is licensed under the GNU General Public License v3.0.

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>