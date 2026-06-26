-- Central bank policy rates, synced weekly from tradingeconomics.com
create table if not exists central_bank_rates (
  currency   text primary key,
  country    text not null,
  rate       float not null,        -- fraction (0.0425 = 4.25%)
  source     text,
  updated_at timestamptz default now()
);

-- Pre-seed with current rates so the table is immediately useful
-- even before the first scrape runs.
insert into central_bank_rates (currency, country, rate, source) values
  ('GBP', 'United Kingdom', 0.0375, 'Bank of England'),
  ('NOK', 'Norway',         0.0425, 'Norges Bank'),
  ('SEK', 'Sweden',         0.0175, 'Riksbanken'),
  ('DKK', 'Denmark',        0.0185, 'Danmarks Nationalbank'),
  ('EUR', 'Euro Area',      0.0240, 'European Central Bank'),
  ('USD', 'United States',  0.0375, 'Federal Reserve'),
  ('CAD', 'Canada',         0.0225, 'Bank of Canada'),
  ('AUD', 'Australia',      0.0435, 'Reserve Bank of Australia'),
  ('NZD', 'New Zealand',    0.0225, 'Reserve Bank of New Zealand'),
  ('CHF', 'Switzerland',    0.0000, 'Swiss National Bank'),
  ('JPY', 'Japan',          0.0100, 'Bank of Japan'),
  ('ISK', 'Iceland',        0.0775, 'Sedlabanki'),
  ('CZK', 'Czech Republic', 0.0375, 'Česká národní banka'),
  ('PLN', 'Poland',         0.0375, 'Narodowy Bank Polski'),
  ('HUF', 'Hungary',        0.0600, 'Magyar Nemzeti Bank'),
  ('SGD', 'Singapore',      0.0108, 'MAS'),
  ('HKD', 'Hong Kong',      0.0400, 'HKMA'),
  ('INR', 'India',          0.0525, 'Reserve Bank of India'),
  ('CNY', 'China',          0.0300, 'People''s Bank of China'),
  ('KRW', 'South Korea',    0.0250, 'Bank of Korea')
on conflict (currency) do nothing;

create index if not exists central_bank_rates_updated on central_bank_rates(updated_at);
