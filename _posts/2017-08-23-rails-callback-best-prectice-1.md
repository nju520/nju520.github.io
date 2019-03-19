---
layout: post
toc: true
permalink: /rails-callback-best-prectice-part-1
title: Rails Callback Best Prectice Part 1
tags: rails callback best prectice
desc: Ruby and Rails are known for their conventions, optimizations for programmer happiness, and an anything-goes mentality (monkey-patching, anyone?). Nonetheless, the language and framework excel when it comes to expressiveness. When dealing with thousands of federal, state, and local taxes—all of which change every single year—the ability to move quickly and safely is important.
 Rails is not without its tradeoffs. Particularly, we’ve found Rails callbacks to be problematic. Callbacks allow you to bind actions to the lifecycle of models, known as ActiveRecord objects, in Rails.

---


Here are our guidelines:
```
Omit when possible
Asynchronous by default
Prefer after_commit to after_save
Avoid conditional execution
Don’t use for data validation
```
### Guideline 1: Omit When Possible
Callbacks ensure that anyone updating or saving a record won't forget to perform an operation that should be performed on #save.

Most parts of our applications directly modify our ActiveRecord::Base subclasses instead of using a service object to perform an operation. More and more, we are trying to use service objects to encapsulate groups of operations rather than callbacks.

Let's take a look at a code example for a hypothetical company onboarding flow:

```ruby
# Bad
class Company < ActiveRecord::Base
  after_commit :send_emails_after_onboarding

  private

  def send_emails_after_onboarding
    if just_finished_onboarding?
      EmailSender.send_emails_for_company!(self)
    end
  end
end

# Good
class Company < ActiveRecord::Base
end

class CompanyOnboarder
  def onboard!(company_params)
    company = Company.new(company_params)
    company.save!
    EmailSender.send_emails_for_company!(company)
  end
end
```
By locating our logic in a service object and not a callback, we are not adding logic that will need to run after every #save. Because we have a service class to handle signing up a company, we also reduce the coupling between Company and EmailSender.

Guideline #2: Asynchronous by default
Whenever we add a callback, that is code that will execute before we can respond to a request. If a class defines 20 callbacks, that's 20 blocks of code that must execute before we can respond to the user. Generally, this will make requests take longer. Requests that take longer result in a sluggish experience on the front-end.

Therefore if you must write a callback, make sure it gets out of the critical path of the request by making the bulk of itself asynchronous. (Note: This only applies to logic that does not need to exist within the same transaction.) For us at Gusto, that means enqueuing a Sidekiq job.

Let'rubys look at an example:

```ruby
# Bad
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification, on: :create

  private

  def create_welcome_notification
    # We're incurring an extra database request here, which
    # is something we want to avoid during
    # critical operations like signing up a
    # new customer
    notifications.create({ title: 'Welcome to Gusto!' })
  end
end

# Good
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification, on: :create

  private

  def create_welcome_notification
    WelcomeNotificationCreator.perform_async(id)
  end
end

class WelcomeNotificationCreator
  include Sidekiq::Worker

  def perform(company_id)
    @company = Company.find(company_id)
    @company.notifications.create({ title: 'Welcome to Gusto!' })
  end
end
```

Now, you might say, “But the 'Good' example is way more code than the 'Bad' one! It now takes 2 files!” You would be correct. Writing callbacks in a safe manner by moving the bulk of the logic into a worker will result in more code. The resulting code, however, will reduce coupling on our models and make each component more testable.

Spearubyking of tests, here's a good way to test callbacks like this using RSpec:

```ruby
# spec/models/company_spec.rb
require 'rails_helper'

RSpec.describe Company, type: :model do
  describe '#save' do
    subject { company.save }
    let(:company) { build(:company) }

    it 'schedules a WelcomeNotificationCreator job' do
      expect {
        subject
      }.to change{ WelcomeNotificationCreator.jobs.size }.by(1)
      last_job = WelcomeNotificationCreator.jobs.last          
      expect(last_job['args']).to eq([subject.id])
    end
  end
end

# spec/workers/welcome_notification_creator_spec.rb
require 'rails_helper'

RSpec.describe WelcomeNotificationCreator do
  subject { described_class.new.perform(company.id)}
  let(:company) { create(:company) }

  it 'creates a notification' do
    expect {
      subject
    }.to change(Notification, :count).by(1)
    expect(Notification.last.title).to eq('Welcome to Gusto!')
  end
end
```

### Guideline 3: Prefer after_commit to after_save
When writing a callback where you want to execute code after a save, create, or update, default to using an after_commit block.

after_commit is the only callback that is triggered once the database transaction is committed. Putting it simply, it's the only callback whose state will match "the outside world," specifically the same state that worker process will see.

Without an after_commit callback, you may see strange errors in Sidekiq to the tune of Cannot find Company with ID=12345. These errors will be frustrating to track down because they will only raise once before passing without a problem.

What's happening with this error is that Sidekiq is picking up the job before the database has committed the new record to it. To the outside world, it looks like your new record does not yet exist. It can be an incredibly frustrating race condition to debug.

The safe default is to use after_commit.

Let'rubys take a look at 2 different code examples:

```ruby
# Bad
class Company < ActiveRecord::Base
  after_create :create_welcome_notification

  private

  def create_welcome_notification
    # The database transaction has not been committed at this point,
    # so there's a chance that the Sidekiq worker will pick up the job
    # before our `Company` has been persisted to the database.
    WelcomeNotificationCreator.perform_async(id)
  end
end

# Good
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification, on: :create

  private

  def create_welcome_notification
    WelcomeNotificationCreator.perform_async(id)
  end
end
```

Please note: The `*_changed?` helpers are not available within after_commit. If you need to conditionally execute a callback, please be aware of this and use the alternative method if looking at the previous_changes hash. Or...

Guideline #4: Avoid conditional execution
As a general rule, do not write callbacks that are conditional.

Instead, try to make callbacks that are idempotent and can be safely run multiple times. This is especially important when you begin moving your callback logic to Sidekiq jobs. (See the best practices on Sidekiq to see why Sidekiq jobs must be idempotent.)

Note that this will enqueue more jobs onto Sidekiq, but many of these jobs should be no-ops.

If you must conditionally execute a job, please define that logic within the method body and not in the callback signature. The reason for this is to make sure that the conditions only live in a single place. It's much easier for the conditional to grow in the method body instead of on the line that defines the conditional.

Let'rubys take a look at a few examples:

```ruby
# Bad
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification, if: -> { should_welcome? && admirable_company? }

  private

  def create_welcome_notification
    WelcomeNotificationCreator.perform_async(id)
  end
end

# Good
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification

  private

  def create_welcome_notification
    if should_welcome? && admirable_company?
      WelcomeNotificationCreator.perform_async(id)
    end
  end
end

# Best
class Company < ActiveRecord::Base
  after_commit :create_welcome_notification

  private

  def create_welcome_notification
    WelcomeNotificationCreator.perform_async(id)
  end
end

class WelcomeNotificationCreator
  include Sidekiq::Worker

  def perform(company_id)
    @company = Company.find(company_id)

    return unless @company.should_welcome? && @company.admirable_company?

    # We passed our check, do the work.
  end
end
```
Please keep in mind that things like on: :create are their own flavor of conditional execution. Generally, try to push that logic into the worker.

### Guideline 5: Don’t use for data validation
It is possible to use callbacks for data validation, but that should be avoided. ActiveRecord makes certain assumptions on how and when validations will be run, and putting these in callbacks breaks some of those assumptions.

Instead, use the ActiveRecord Validations API.

Conclusion
With great power comes great responsibility, and Rails callbacks are no exception. They are expressive tools but also come with drawbacks.

We are generally moving away from using callbacks and toward using rich service objects in our applications, but we still have many callbacks that exist. We still have a lot left to do, but we’ve found that the code that follows these guidelines requires less maintenance.
