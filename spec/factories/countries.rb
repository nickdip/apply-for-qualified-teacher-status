# == Schema Information
#
# Table name: countries
#
#  id                         :bigint           not null, primary key
#  code                       :string           not null
#  eligibility_enabled        :boolean          default(TRUE), not null
#  eligibility_skip_questions :boolean          default(FALSE), not null
#  other_information          :text             default(""), not null
#  qualifications_information :text             default(""), not null
#  sanction_information       :string           default(""), not null
#  status_information         :string           default(""), not null
#  subject_limited            :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_countries_on_code  (code) UNIQUE
#
FactoryBot.define do
  factory :country do
    sequence :code, Country::CODES.cycle

    trait :subject_limited do
      subject_limited { true }
    end

    trait :with_national_region do
      after(:create) do |country, _evaluator|
        create(:region, :national, country:)
      end
    end
  end
end
