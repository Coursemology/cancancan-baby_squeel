# CanCanCan-BabySqueel
[![Build Status](https://travis-ci.org/Coursemology/cancancan-baby_squeel.svg?branch=master)](https://travis-ci.org/Coursemology/cancancan-baby_squeel)
[![Coverage Status](https://coveralls.io/repos/github/Coursemology/cancancan-baby_squeel/badge.svg?branch=master)](https://coveralls.io/github/Coursemology/cancancan-baby_squeel?branch=master)

This is an adapter for the [CanCanCan](https://github.com/CanCanCommunity/cancancan) authorisation
library to automatically generate SQL queries from ability rules.

This differs from the default ActiveRecord implementation in that it uses
[baby_squeel](https://github.com/rzane/baby_squeel) to generate SQL queries. This no longer
uses
 - `includes` (which incurs eager loading overhead)
 - `WHERE` fragments, joined lexically using `OR` or `AND` or `NOT`.

As a side effect of using `squeel`, this allows self-joins in rule definitions.

## Usage

In your `Gemfile`, insert the following line:

```ruby
gem 'cancancan-baby_squeel'
```

after you included `cancancan`.
