foo:
    - name: {{sls}}

bar:
    - name: '{{sls}}'
    
car:
    - name: "{{sls}}"

dar:
    - name: Test {{sls['salt']}}

ear:
    - name: Test {{sls["salt"]}}
