#! python

import yaml
import sys
import os
import logging

def load_rules(path):
  with open(path, 'r') as stream:
    try:
      patch = yaml.safe_load(stream)

      if patch == None: 
        raise Exception("Nothing in patch file")
      
      rules = patch.get("rules")
      if rules.get("addAnnotation") != None:
        for rule in rules.get("addAnnotation"):
          rule["matchLabel"] = rule.get("matchLabel").split(": ")
          rule["addAnnotation"] = rule.get("addAnnotation").split(": ")

      if rules.get("patchField") != None:
        for rule in rules.get("patchField"):
          rule["matchLabel"] = rule.get("matchLabel").split(": ")
          rule["specField"] = rule.get("specField").split(".")

      return rules
    except yaml.YAMLError as exc:
      raise exc

def load_common_templates(path):
  try:
    with open(path, 'r') as stream:
      commonTemplates = list(yaml.safe_load_all(stream))
      if len(commonTemplates) == 0: 
        raise Exception("Nothing in common templates file")

      return commonTemplates

  except yaml.YAMLError as exc:
    raise exc 

def process_rules(commonTemplates, rules):
  for template in commonTemplates:
      metadata = template.get("metadata", {})
      annotations = metadata.get("annotations",{})
      labels = metadata.get("labels", {})
      annotationsAdded = []
      addAnnotationRules = rules.get("addAnnotation")
      if addAnnotationRules != None:
        for rule in addAnnotationRules:
          key = rule.get("matchLabel")[0]
          value = rule.get("matchLabel")[1]
          if labels.get(key) == value:
            annotationKey = rule.get("addAnnotation")[0]
            annotationValue = rule.get("addAnnotation")[1]
            annotations[annotationKey] = annotationValue
            annotationsAdded.append("adding " + annotationKey + ": " +  annotationValue)

      fieldsUpdated = []
      patchFieldRules = rules.get("patchField")
      if patchFieldRules != None:
        for rule in patchFieldRules:
          key = rule.get("matchLabel")[0]
          value = rule.get("matchLabel")[1]
          if labels.get(key) == value:
            obj = template
            specFieldPath = rule.get("specField")
            lastPathPiece = ""
            for index, path in enumerate(specFieldPath):
              if (index+1) == len(specFieldPath):
                lastPathPiece = path
                break
              if type(obj) == list:
                obj = obj[int(path)]
              else:
                obj = obj.setdefault(path, {})
            obj[lastPathPiece] = rule.get("value")
            fieldsUpdated.append("field " + ".".join(specFieldPath) + " updated with value: " + str(rule.get("value")))

      if len(annotationsAdded) > 0 or len(fieldsUpdated) > 0:
        logging.info("Updating "+ metadata.get("name")+ " template")
        for msg in annotationsAdded + fieldsUpdated:
          logging.info(msg)

  return commonTemplates

def process_common_templates(commonTemplatesPath, rules):
  files = [f for f in os.listdir(commonTemplatesPath) if os.path.isfile(os.path.join(commonTemplatesPath, f))]

  for fileName in files:
    commonTemplates = None
    try:
      commonTemplates = load_common_templates(commonTemplatesPath+fileName)
    except yaml.YAMLError as exc:
      logging.warning(exc)
      continue

    logging.info("------------------------------------------------------")
    logging.info("Running script for file: " + fileName)
    logging.info("------------------------------------------------------")

    updatedCommonTemplates = process_rules(commonTemplates, rules)

    outputFilePath = commonTemplatesPath+fileName
    try:
      with open(outputFilePath, 'w') as outfile:
        yaml.safe_dump_all(updatedCommonTemplates, outfile, default_flow_style=False)
    except yaml.YAMLError as exc:
      logging.warning(exc)
      continue



if __name__ == "__main__":
  logging.basicConfig(level=logging.INFO)

  logging.info("Running preprocessing for common templates")

  patchPath = sys.argv[1] if len(sys.argv) > 1 else "patch.yaml"
  rules = None
  try:
    rules = load_rules(patchPath)
  except Exception as e:
    logging.error(e)
    sys.exit(1)

  commonTemplatesPath = sys.argv[2] if len(sys.argv) > 2 else "/opt/ansible/roles/KubevirtCommonTemplatesBundle/files"
  try:
    process_common_templates(commonTemplatesPath, rules)
  except Exception as e:
    logging.error(e)
    sys.exit(1)
    

