# Test quoting of keys
#
key:
    - value

{{ salt.random.shadow_hash() }}:
    test:
        - name: foobar
        
{{ sls }}.packages.{{ salt.random.shadow_hash() }}:
    test:
        - name: foobar

'{{ salt.random.shadow_hash() }}':
    test:
        - name: gherkin

