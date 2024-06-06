#  Test commented out code with jinja tokens, should be single quoted
#
# {{ salt.random.shadow_hash() }}:
#    - test: value
#
#  And the following code should be commented out
#
{% if ( (foo == 'foo' or bar == 'bar') and 
        (fooo == 'fooo' or baar == 'baar') ) %}
test:
    test.nop
{% endif %}
