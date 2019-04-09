#! python

import yaml
import sys
import os
import logging


class MissingPatch(Exception):
    pass


def load_rules(path):
  with open(path, 'r') as stream:
    try:
      patch = yaml.load(stream, Loader=yaml.BaseLoader)

      if patch == None: 
        raise MissingPatch("Nothing in patch file")
      
      rules = patch.get("rules")
      for rule in rules:
        rule["matchLabel"] = rule.get("matchLabel").split(": ")
        rule["addAnnotation"] = rule.get("addAnnotation").split(": ")

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

def process_annotations(commonTemplates, rules):
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
        logging.info("Updating "+ metadata.get("name")+ " template")
        for a in annotationsAdded:
          logging.info("adding " + a)
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

    updatedCommonTemplates = process_annotations(commonTemplates, rules)

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
  except MissingPatch:
    # nothing to do, let's just bail out
    logging.info("Empty patch file %s detected - nothing to do", patchPath)
    sys.exit(0)
  except Exception as e:
    logging.error(e)
    sys.exit(1)

  commonTemplatesPath = sys.argv[2] if len(sys.argv) > 2 else "/opt/ansible/roles/KubevirtCommonTemplatesBundle/files"
  try:
    process_common_templates(commonTemplatesPath, rules)
  except Exception as e:
    logging.error(e)
    sys.exit(1)
    

