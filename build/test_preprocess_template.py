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
    "rulesParsed": [{
      "matchLabel":["common_templates1", "true"],
      "addAnnotation": ["new_annotation", "true"]
    }],
    "rulesRaw": {
      "rules": [
        {
          "matchLabel":"common_templates1: true",
          "addAnnotation": "new_annotation: true"
        }
      ]
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
    "rulesParsed": [{
      "matchLabel":["match_label", "true"],
      "addAnnotation": ["new_annotation", "true"]
    }],
    "rulesRaw": {
      "rules": [
        {
          "matchLabel":"match_label: true",
          "addAnnotation": "new_annotation: true"
        }
      ]
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
        }
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
      "rules": [{
        "matchLabel":"match_label: true",
        "addAnnotation": "new_annotation1: true"
      }, {
        "matchLabel":"common_templates1: true",
        "addAnnotation": "new_annotation2: true"
      }]
    },    
    "rulesParsed": [
      {
        "matchLabel":["match_label", "true"],
        "addAnnotation": ["new_annotation1", "true"]
      }, {
        "matchLabel":["common_templates1", "true"],
        "addAnnotation": ["new_annotation2", "true"]
      }
    ],
    "resultAnnotations":[{
      "my_annotation1": "true",
      "new_annotation1": "true",
      "new_annotation2": "true"
    },
    {
      "my_annotation2": "true"
    }] 
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
    "rulesParsed": [{
      "matchLabel":["match_label", "true"],
      "addAnnotation": ["new_annotation1", "true"]
    }, {
      "matchLabel":["common_templates", "true"],
      "addAnnotation": ["new_annotation2", "true"]
    }],
    "rulesRaw": {
      "rules": [
        {
          "matchLabel":"match_label: true",
          "addAnnotation": "new_annotation1: true"
        }, {
          "matchLabel":"common_templates: true",
          "addAnnotation": "new_annotation2: true"
        }
      ]
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
    "rulesParsed": [{
      "matchLabel":["some_nonsense1", "true"],
      "addAnnotation": ["new_annotation1", "true"]
    }, {
      "matchLabel":["some_nonsense2", "true"],
      "addAnnotation": ["new_annotation2", "true"]
    }],
    "rulesRaw": {
      "rules": [
        {
          "matchLabel":"some_nonsense1: true",
          "addAnnotation": "new_annotation1: true"
        }, {
          "matchLabel":"some_nonsense2: true",
          "addAnnotation": "new_annotation2: true"
        }
      ]
    },
    "resultAnnotations":[{
      "my_annotation1": "true"
    },
    {
      "my_annotation2": "true"
    }] 
  }
]


def test_process_annotations():
  for testCase in testCases:
    commonTemplates = testCase.get("commonTemplates")
    updatesCommonTemplates = preprocess_template.process_annotations(commonTemplates, testCase.get("rulesParsed"))
    for index, resultAnnotation in enumerate(testCase.get("resultAnnotations")):
      updatedAnnotations = updatesCommonTemplates[index].get("metadata").get("annotations")
      for key in resultAnnotation.keys():
        #compare if updated common templates have correct annotations
        assert updatedAnnotations.get(key) == resultAnnotation.get(key), "annotations should equal"

def test_load_rules():
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
      #load parsed rules
      rules = preprocess_template.load_rules(patchPath)
      parsedRulesResult = testCase.get("rulesParsed")
      for index, rule in enumerate(rules):
        #compare if load and parsed rules are the same as result rules
        matchLabel = rule.get("matchLabel")
        matchLabelResult = parsedRulesResult[index].get("matchLabel")
        assert matchLabel[0] == matchLabelResult[0], "matchLabel key should equal"
        assert matchLabel[1] == matchLabelResult[1], "matchLabel value should equal"

        addAnnotation = rule.get("addAnnotation")
        addAnnotationResult = parsedRulesResult[index].get("addAnnotation")
        assert addAnnotation[0] == addAnnotationResult[0], "addAnnotation key should equal"
        assert addAnnotation[1] == addAnnotationResult[1], "addAnnotation value should equal"
    except Exception as e:
      raise e
  
  os.remove(patchPath)

def test_process_common_templates():
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


    except Exception as e:
      raise e 
  #delete temporary folder
  shutil.rmtree(commonTemplatesPath, ignore_errors=True)


if __name__ == "__main__":
  test_process_annotations()
  test_load_rules()
  test_process_common_templates()
  print("Everything passed")