# After The Deadline - Ruby Library

Ruby library for working with After The Deadline service.
See http://www.afterthedeadline.com/api.slp for the API documentation.

## Installation

Add this line to your application's Gemfile:

    gem 'after_the_deadline'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install after_the_deadline

## Standard Usage

    require 'after_the_deadline'
    AfterTheDeadline(nil, nil) # no custom dictionary, accept all error types

### No Errors

    AfterTheDeadline.check 'this text is clean.'
    => []

### Error: Missing Apostrophe

    AfterTheDeadline.check 'this text isnt clean.'
    => [#<AfterTheDeadline::Error:0x101614e80 @url=nil, @description="Missing apostrophe", @string="isnt", @suggestions=["isn't"], @type="grammar", @precontext="text">]

### Error: Passive Voice

    errors = AfterTheDeadline.check 'this text should be written in a passive voice.'
    => [#<AfterTheDeadline::Error:0x1015c1960 @url="http://service.afterthedeadline.com/info.slp?text=should+be&tags=MD%2FVB", @description="Passive voice", @string="should be", @suggestions=[], @type="grammar", @precontext="text">]

### Information on the Passive Voice Error

    errors.first.info
    => "<h3>Revise <em>should be</em> with active voice</h3>\n\n<p>Active voice makes it clear who is doing what.  In an active sentence, the person that is acting is the subject.  Passive sentences obscure or omit the sentence \nsubject.<br><br>Use passive voice when the sentence object is more important than the subject.  The active voice is generally easier to read.\n<br>\n<br><b>Examples</b> (<i><b>subject</b></i>, <u>object</u>)\n<br>\n<br>Before: <u>Our results</u> will be discussed.\n<br>After: <i><b>We</b></i> will discuss <u>our results</u>.\n<br>\n<br>Before: <i><b>Wolverine</b></i> was made to be a <u>weapon</u>.\n<br>After: <i><b>The government</b></i> made <u>Wolverine</u>. <i><b>Wolverine</b></i> is a <u>weapon</u>. </p>"

### Metrics

    AfterTheDeadline.metrics 'this text should be written in a passive voice. another sentence is used to get more data in the metrics.'
    => #<AfterTheDeadline::Metrics:0x10159d4e8 @stats={"words"=>"20", "sentences"=>"1"}, @grammer={}, @spell={}, @style={"passive voice"=>"2"}>

## Ignoring Specific Types of Errors

    require 'after_the_deadline'
    AfterTheDeadline(nil, ['Passive voice'])

### Skip the Passive Voice Error

    errors = AfterTheDeadline.check 'this text should be written in a passive voice.'
    => []

## Using a Custom Dictionary

    require 'after_the_deadline'
    AfterTheDeadline(['Sepcot']) # or AfterTheDeadline('path/to/filename')
    AfterTheDeadline.check "My last name, Sepcot, is very unique."
    => []

## Multilanguage

After the deadline service provides 5 languages:

* English (en, default)
* French (fr)
* German (de)
* Spanish (es)
* Portuguese (pt)

If no language is set English is choosen by default. To set another language simply set it:

    AfterTheDeadline.set_language('de') # possible values en, fr, de, es, pt

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
