#! python

import yaml
import sys
from os import listdir
from os.path import isfile, join

if __name__ == "__main__":

  print("Running preprocessing for common templates")

  rules = None
  patchPath = sys.argv[1] if len(sys.argv) > 1 else "patch.yaml"
  with open(patchPath, 'r') as stream:
    try:
      patch = yaml.load(stream, Loader=yaml.BaseLoader)

      if patch == None: 
        print("Nothing in patch file")
        sys.exit(0)
      
      rules = patch.get("rules")
      for rule in rules:
        rule["matchLabel"] = rule.get("matchLabel").split(": ")
        rule["addAnnotation"] = rule.get("addAnnotation").split(": ")
    except yaml.YAMLError as exc:
      print(exc)
      sys.exit(1)

  commonTemplatesPath = sys.argv[2] if len(sys.argv) > 2 else "/opt/ansible/roles/KubevirtCommonTemplatesBundle/files"
  files = [f for f in listdir(commonTemplatesPath) if isfile(join(commonTemplatesPath, f))]

  for fileName in files:

    commonTemplates = None
    with open(commonTemplatesPath+fileName, 'r') as stream:
      try:
        commonTemplates = list(yaml.safe_load_all(stream))
        if len(commonTemplates) == 0: 
          print("Nothing in common templates file")
          continue

      except yaml.YAMLError as exc:
        print(exc)
        continue

    print("------------------------------------------------------")
    print("Running script for file: " + fileName)
    print("------------------------------------------------------")

    for template in commonTemplates:
      metadata = template.get("metadata", {})
      annotations = metadata.get("annotations",{})
      labels = metadata.get("labels", {})
      annotationsAdded = []
      for rule in rules:
        key = rule.get("matchLabel")[0]
        value = rule.get("matchLabel")[1]
        if labels.get(key) == value:
          annotationKey = rule.get("addAnnotation")[0]
          annotationValue = rule.get("addAnnotation")[1]
          annotations[annotationKey] = annotationValue
          annotationsAdded.append(annotationKey + ": " +  annotationValue)

      if len(annotationsAdded) > 0:
        print("Updating "+ metadata.get("name")+ " template")
        for a in annotationsAdded:
          print("adding " + a)

    outputFilePath = commonTemplatesPath+fileName
    with open(outputFilePath, 'w') as outfile:
      yaml.safe_dump_all(outputFilePath, outfile, default_flow_style=False)  
