import preprocess_template
import yaml
import os
import shutil

testCases = [
  {
    #one rule, match only one template
    "commonTemplates": [{
        "metadata": {
          "name": "template1",
          "annotations": {
            "my_annotation1": "true"
          },
          "labels": {
            "common_templates1": "true",
            "other_label1": "true"
          }
        }
      },{
        "metadata": {
          "name": "template2",
          "annotations": {
            "my_annotation2": "true"
          },
          "labels": {
            "common_templates2": "true",
            "other_label2": "true"
          }
        }
      }],        
    "rulesParsed": {
      "addAnnotation": [{
          "matchLabel":["common_templates1", "true"],
          "addAnnotation": ["new_annotation", "true"]
        }
      ],
      "patchField": [
        {
          "matchLabel": ["common_templates1", "true"], 
          "specField": ["objects", "0", "spec", "template", "spec", "domain", "cpu", "sockets"],
          "value": 3
        }
      ]
    },
    "rulesRaw": {
      "rules": {
        "addAnnotation": [
          {
            "matchLabel":"common_templates1: true",
            "addAnnotation": "new_annotation: true"
          }
        ],
        "patchField": [
          {
            "matchLabel": "common_templates1: true", 
            "specField": "objects.0.spec.template.spec.domain.cpu.sockets",
            "value": 3
          }
        ]
      }
    },
    "resultAnnotations":[{
      "my_annotation1": "true",
      "new_annotation": "true"
    },
    {
      "my_annotation2": "true"
    }] 
  }, {
    #one rule, match both templates
    "commonTemplates": [{
        "metadata": {
          "name": "template1",
          "annotations": {
            "my_annotation1": "true"
          },
          "labels": {
            "common_templates1": "true",
            "match_label": "true"
          }
        }
      },{
        "metadata": {
          "name": "template2",
          "annotations": {
            "my_annotation2": "true"
          },
          "labels": {
            "common_templates2": "true",
            "match_label": "true"
          }
        }
      }],        
    "rulesParsed": {
      "addAnnotation": [{
          "matchLabel":["match_label", "true"],
          "addAnnotation": ["new_annotation", "true"]
        }
      ],
      "patchField": [
        {
          "matchLabel": ["match_label", "true"], 
          "specField": ["a", "b", "c"],
          "value": "a"
        }
      ]
    },
    "rulesRaw": {
      "rules": {
        "addAnnotation": [
          {
            "matchLabel":"match_label: true",
            "addAnnotation": "new_annotation: true"
          }
        ],
        "patchField": [
          {
            "matchLabel": "match_label: true", 
            "specField": "a.b.c",
            "value": "a"
          }
        ]
      }
    },
    "resultAnnotations":[{
      "my_annotation1": "true",
      "new_annotation": "true"
    },
    {
      "my_annotation2": "true",
      "new_annotation": "true"
    }] 
  }, {
    #multiple rules, match only one template
    "commonTemplates": [{
        "metadata": {
          "name": "template1",
          "annotations": {
            "my_annotation1": "true"
          },
          "labels": {
            "common_templates1": "true",
            "match_label": "true"
          }
        },
        "a": [{},{"b":{"c": 5}}]
      },{
        "metadata": {
          "name": "template2",
          "annotations": {
            "my_annotation2": "true"
          },
          "labels": {
            "common_templates2": "true",
            "some_other_label": "true"
          }
        }
      }],
    "rulesRaw": {
      "rules": {
        "addAnnotation": [
          {
            "matchLabel":"match_label: true",
            "addAnnotation": "new_annotation1: true"
          }, {
            "matchLabel":"common_templates1: true",
            "addAnnotation": "new_annotation2: true"
          }
        ],
        "patchField": [
          {
            "matchLabel": "match_label: true", 
            "specField": "a.1.b.c",
            "value": 3
          }
        ]
      }
    },    
    "rulesParsed": {
      "addAnnotation": [
        {
          "matchLabel":["match_label", "true"],
          "addAnnotation": ["new_annotation1", "true"]
        }, {
          "matchLabel":["common_templates1", "true"],
          "addAnnotation": ["new_annotation2", "true"]
        }
      ],
      "patchField": [
        {
          "matchLabel": ["match_label", "true"], 
          "specField": ["a", "1", "b", "c"],
          "value": 3
        }
      ]
    },
    "resultAnnotations":[
      {
        "my_annotation1": "true",
        "new_annotation1": "true",
        "new_annotation2": "true"
      },
      {
        "my_annotation2": "true"
      }
    ] 
  }, {
    #multiple rules, match both templates
    "commonTemplates": [{
        "metadata": {
          "name": "template1",
          "annotations": {
            "my_annotation1": "true"
          },
          "labels": {
            "common_templates": "true",
            "match_label": "true"
          }
        }
      },{
        "metadata": {
          "name": "template2",
          "annotations": {
            "my_annotation2": "true"
          },
          "labels": {
            "common_templates": "true",
            "match_label": "true"
          }
        }
      }],        
    "rulesParsed": {
      "addAnnotation": [{
          "matchLabel":["match_label", "true"],
          "addAnnotation": ["new_annotation1", "true"]
        }, {
          "matchLabel":["common_templates", "true"],
          "addAnnotation": ["new_annotation2", "true"]
        }
      ],
      "patchField": [
        {
          "matchLabel": ["match_label", "true"], 
          "specField": ["a", "0", "b", "c"],
          "value": 1
        }, {
            "matchLabel": ["match_label", "true"], 
            "specField": ["a", "0", "d", "e", "f", "g"],
            "value": 1
          }
      ]
    },
    "rulesRaw": {
      "rules": {
        "addAnnotation": [
          {
            "matchLabel":"match_label: true",
            "addAnnotation": "new_annotation1: true"
          }, {
            "matchLabel":"common_templates: true",
            "addAnnotation": "new_annotation2: true"
          }
        ],
        "patchField": [
          {
            "matchLabel": "match_label: true", 
            "specField": "a.0.b.c",
            "value": 1
          }, {
            "matchLabel": "match_label: true", 
            "specField": "a.0.d.e.f.g",
            "value": 1
          }
        ]
      }
    },
    "resultAnnotations":[{
      "my_annotation1": "true",
      "new_annotation1": "true",
      "new_annotation2": "true"
    },
    {
      "my_annotation2": "true",
      "new_annotation1": "true",
      "new_annotation2": "true"
    }] 
  }, {
    #multiple rules, match none template
    "commonTemplates": [{
        "metadata": {
          "name": "template1",
          "annotations": {
            "my_annotation1": "true"
          },
          "labels": {
            "common_templates": "true",
            "match_label": "true"
          }
        }
      },{
        "metadata": {
          "name": "template2",
          "annotations": {
            "my_annotation2": "true"
          },
          "labels": {
            "common_templates": "true",
            "match_label": "true"
          }
        }
      }],        
    "rulesParsed": {
      "addAnnotation": [{
          "matchLabel":["some_nonsense1", "true"],
          "addAnnotation": ["new_annotation1", "true"]
        }, {
          "matchLabel":["some_nonsense2", "true"],
          "addAnnotation": ["new_annotation2", "true"]
        }
      ],
      "patchField": [
        {
          "matchLabel": ["some_nonsense2", "true"], 
          "specField": ["a", "0", "b", "c"],
          "value": 1
        }
      ]
    },
    "rulesRaw": {
      "rules": {
        "addAnnotation": [
          {
            "matchLabel":"some_nonsense1: true",
            "addAnnotation": "new_annotation1: true"
          }, {
            "matchLabel":"some_nonsense2: true",
            "addAnnotation": "new_annotation2: true"
          }
        ],
        "patchField": [
          {
            "matchLabel": "some_nonsense2: true", 
            "specField": "a.0.b.c",
            "value": 1
          }
        ]
      }
    },
    "resultAnnotations":[{
      "my_annotation1": "true"
    },
    {
      "my_annotation2": "true"
    }] 
  }
]


def test_process_rules():
  print("Running test_process_rules")
  for testCase in testCases:
    commonTemplates = testCase.get("commonTemplates")
    updatesCommonTemplates = preprocess_template.process_rules(commonTemplates, testCase.get("rulesParsed"))
    for index, resultAnnotation in enumerate(testCase.get("resultAnnotations")):
      updatedAnnotations = updatesCommonTemplates[index].get("metadata").get("annotations")
      for key in resultAnnotation.keys():
        #compare if updated common templates have correct annotations
        assert updatedAnnotations.get(key) == resultAnnotation.get(key), "annotations should equal"
    
    patchRules = testCase.get("rulesParsed").get("patchField")
    for patchRule in patchRules:
      matchLabel = patchRule.get("matchLabel")
      for updatedTemplate in updatesCommonTemplates:
        metadata = updatedTemplate.get("metadata")
        # test rule, only if updated template contains match label
        if metadata.get("labels").get(matchLabel[0]) == matchLabel[1]:
          path = patchRule.get("specField")
          obj = updatedTemplate
          for field in path:
            if type(obj) == list:
              obj = obj[int(field)]
            else:
              obj = obj.get(field)
          assert obj == patchRule.get("value"), "values should equal"
    

def test_load_rules():
  print("Running test_load_rules")
  patchPath = "/tmp/patch.yaml"
  for testCase in testCases:
    rawRules = testCase.get("rulesRaw")
    #save rules as yaml
    try:
      with open(patchPath, 'w') as outfile:
        yaml.safe_dump(rawRules, outfile, default_flow_style=False)
    except Exception as e:
      raise e
    try:
      #load parsed annotations rules
      rules = preprocess_template.load_rules(patchPath)
      addAnnotationrules = rules.get("addAnnotation")
      addAnnotationRulesResult = testCase.get("rulesParsed").get("addAnnotation")
      for index, rule in enumerate(addAnnotationrules):
        #compare if load and parsed rules are the same as result rules
        matchLabel = rule.get("matchLabel")
        matchLabelResult = addAnnotationRulesResult[index].get("matchLabel")
        assert matchLabel[0] == matchLabelResult[0], "matchLabel key should equal, "
        assert matchLabel[1] == matchLabelResult[1], "matchLabel value should equal"

        addAnnotation = rule.get("addAnnotation")
        addAnnotationResult = addAnnotationRulesResult[index].get("addAnnotation")
        assert addAnnotation[0] == addAnnotationResult[0], "addAnnotation key should equal"
        assert addAnnotation[1] == addAnnotationResult[1], "addAnnotation value should equal"

      patchFieldrules = rules.get("patchField")
      patchFieldRulesResult = testCase.get("rulesParsed").get("patchField")
      for index, rule in enumerate(patchFieldrules):
        #compare if load and parsed rules are the same as result rules
        matchLabel = rule.get("matchLabel")
        matchLabelResult = patchFieldRulesResult[index].get("matchLabel")

        assert matchLabel[0] == matchLabelResult[0], "patchField matchLabel key should equal"
        assert matchLabel[1] == matchLabelResult[1], "patchField matchLabel value should equal"

        specFields = rule.get("specField")
        specFieldsResult = patchFieldRulesResult[index].get("specField")
        for i, field in enumerate(specFields):
          assert field == specFieldsResult[i], "path parts should equal"
        
        valueResult = patchFieldRulesResult[index].get("value")
        ruleValue = rule.get("value")
        assert valueResult == ruleValue, "values should equal"

    except Exception as e:
      raise e
  
  os.remove(patchPath)

def test_process_common_templates():
  print("Running process_common_templates")
  commonTemplatesPath = "/tmp/commonTemplates/"
  #create temporary folder
  if not os.path.exists(commonTemplatesPath):
    os.makedirs(commonTemplatesPath)

  for testCase in testCases:
    try:
      #create file with mock common templates
      with open(commonTemplatesPath + "commonTemplate.yaml", 'w') as outfile:
        commonTemplates = testCase.get("commonTemplates")
        yaml.safe_dump_all(commonTemplates, outfile, default_flow_style=False)
    except Exception as e:
      raise e
    #get already parsed rules
    rules = testCase.get("rulesParsed")
    try:
      #update common templates
      preprocess_template.process_common_templates(commonTemplatesPath, rules)
      with open(commonTemplatesPath + "commonTemplate.yaml", 'r') as stream:
        #load updated common templates
        updatedCommonTemplates = list(yaml.safe_load_all(stream))
        #go through updated common templates
        for index, updatedTemplate in enumerate(updatedCommonTemplates):
          metadata = updatedTemplate.get("metadata")
          annotations = metadata.get("annotations")
          #get result annotations
          resultAnnotations = testCase.get("resultAnnotations")[index]
          #go through result annotations
          for key in resultAnnotations:
            #compare if result annotations are the same as updated annotations
            assert annotations.get(key) == resultAnnotations.get(key), "annotations should equal"
          
          patchRules = testCase.get("rulesParsed").get("patchField")
          for patchRule in patchRules:
            matchLabel = patchRule.get("matchLabel")
            # test rule, only if updated template contains match label
            if metadata.get("labels").get(matchLabel[0]) == matchLabel[1]:
              path = patchRule.get("specField")
              obj = updatedTemplate
              for field in path:
                if type(obj) == list:
                  obj = obj[int(field)]
                else:
                  obj = obj.get(field)
              assert obj == patchRule.get("value"), "values should equal"


    except Exception as e:
      raise e 
  #delete temporary folder
  shutil.rmtree(commonTemplatesPath, ignore_errors=True)


if __name__ == "__main__":
  test_process_rules()
  test_load_rules()
  test_process_common_templates()
  print("Everything passed")