#!/usr/bin/env python

import fnmatch
import yaml
import sys
import os
import logging


class MissingPatch(Exception):
    pass


class MalformedMatchRule(Exception):
    pass


class MatchRuleKV:
    def __init__(self, key, value):
        self._key = key
        self._value = value

    def matches(self, labels):
          return labels.get(self._key) == self._value

    def __str__(self):
        return "%s: %s" % (self._key, self._value)

    __repr__ = __str__

    def __eq__(self, mr):
        return self._key == mr._key and self._value == mr._value


class MatchRulePattern:
    def __init__(self, pattern):
        self._pattern = pattern

    def matches(self, labels):
        for lab in labels:
            if fnmatch.fnmatch(lab, self._pattern):
                return True
        return False

    def __str__(self):
        return self._pattern

    __repr__ = __str__

    def __eq__(self, mr):
        return self._pattern == mr._pattern


def parse_rule_matcher(rule):
    if 'matchLabelPattern' in rule:
        return MatchRulePattern(rule.pop('matchLabelPattern'))
    if 'matchLabel' in rule:
        key, value = rule.pop('matchLabel').split(": ")
        return MatchRuleKV(key, value)
    raise MalformedMatcheRule(rule)


def load_rules(path):
  with open(path, 'r') as stream:
    try:
      patch = yaml.safe_load(stream)

      if patch == None: 
        raise MissingPatch("Nothing in patch file")
      
      rules = patch.get("rules")
      if rules.get("addAnnotation") != None:
        for rule in rules.get("addAnnotation"):
          rule["matchLabel"] = parse_rule_matcher(rule)
          rule["addAnnotation"] = rule.get("addAnnotation").split(": ")

      if rules.get("patchField") != None:
        for rule in rules.get("patchField"):
          rule["matchLabel"] = parse_rule_matcher(rule)
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


def match_rule(rule, labels):
  try:
    return rule["matchLabelPattern"].matches(labels)
  except KeyError:
    return rule["matchLabel"].matches(labels)


def process_rules(commonTemplates, rules):
  for template in commonTemplates:
      metadata = template.get("metadata", {})
      annotations = metadata.get("annotations",{})
      labels = metadata.get("labels", {})
      annotationsAdded = []
      addAnnotationRules = rules.get("addAnnotation")
      if addAnnotationRules != None:
        for rule in addAnnotationRules:
          if match_rule(rule, labels):
            annotationKey = rule.get("addAnnotation")[0]
            annotationValue = rule.get("addAnnotation")[1]
            annotations[annotationKey] = annotationValue
            annotationsAdded.append("adding " + annotationKey + ": " +  annotationValue)

      fieldsUpdated = []
      patchFieldRules = rules.get("patchField")
      if patchFieldRules != None:
        for rule in patchFieldRules:
          if match_rule(rule, labels):
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
            oldValue = obj.get(lastPathPiece, None)
            obj[lastPathPiece] = rule.get("value")
            fieldsUpdated.append("field %r updated: %r -> %r" % (
                ".".join(specFieldPath), oldValue, rule.get("value")))

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
    logging.info("Running script for file: %s (%i templates)",
                 fileName, len(commonTemplates))
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
    

