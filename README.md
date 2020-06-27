# dotenv module for V

Which loads env vars from a .env file.


## Installation and Import

### Using vpm:

Install/Update:
```
v install zztkm.vdotenv
```

Import:
```v
import zztkm.vdotenv
```

## Examples

```v
impor os

import zztkm.vdotenv

fn main() {
    // loads env vars from a .env file.
    vdotenv.load()

    env_var = os.getenv('YOUR_ENV_VAR')
    println(env_var)
}
```

## License

[MIT License](LICENSE.txt)