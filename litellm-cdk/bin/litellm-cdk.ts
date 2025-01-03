#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { LitellmCdkStack } from '../lib/litellm-cdk-stack';

const app = new cdk.App();
const architecture = app.node.tryGetContext('architecture');
const liteLLMVersion = app.node.tryGetContext('liteLLMVersion');
const ecrLitellmRepository = String(app.node.tryGetContext("ecrLitellmRepository"));
const ecrMiddlewareRepository = String(app.node.tryGetContext("ecrMiddlewareRepository"));
const certificateArn = String(app.node.tryGetContext("certificateArn"));
const domainName = String(app.node.tryGetContext("domainName"));
const oktaIssuer = String(app.node.tryGetContext("oktaIssuer"));
const oktaAudience = String(app.node.tryGetContext("oktaAudience"));
const logBucketArn = String(app.node.tryGetContext("logBucketArn"));
const openaiApiKey = String(app.node.tryGetContext("openaiApiKey"));
const azureOpenAiApiKey = String(app.node.tryGetContext("azureOpenAiApiKey"));
const azureApiKey = String(app.node.tryGetContext("azureApiKey"));
const anthropicApiKey = String(app.node.tryGetContext("anthropicApiKey"));
const groqApiKey = String(app.node.tryGetContext("groqApiKey"));
const cohereApiKey = String(app.node.tryGetContext("cohereApiKey"));
const coApiKey = String(app.node.tryGetContext("coApiKey"));
const hfToken = String(app.node.tryGetContext("hfToken"));
const huggingfaceApiKey = String(app.node.tryGetContext("huggingfaceApiKey"));
const databricksApiKey = String(app.node.tryGetContext("databricksApiKey"));
const geminiApiKey = String(app.node.tryGetContext("geminiApiKey"));
const codestralApiKey = String(app.node.tryGetContext("codestralApiKey"));
const mistralApiKey = String(app.node.tryGetContext("mistralApiKey"));
const azureAiApiKey = String(app.node.tryGetContext("azureAiApiKey"));

const nvidiaNimApiKey = String(app.node.tryGetContext("nvidiaNimApiKey"));
const xaiApiKey = String(app.node.tryGetContext("xaiApiKey"));
const perplexityaiApiKey = String(app.node.tryGetContext("perplexityaiApiKey"));
const githubApiKey = String(app.node.tryGetContext("githubApiKey"));
const deepseekApiKey = String(app.node.tryGetContext("deepseekApiKey"));

new LitellmCdkStack(app, 'LitellmCdkStack', {
  domainName: domainName,
  certificateArn: certificateArn,
  oktaIssuer: oktaIssuer,
  oktaAudience: oktaAudience,
  liteLLMVersion: liteLLMVersion,
  architecture: architecture,
  ecrLitellmRepository: ecrLitellmRepository,
  ecrMiddlewareRepository: ecrMiddlewareRepository,
  logBucketArn: logBucketArn,
  openaiApiKey: openaiApiKey,
  azureOpenAiApiKey: azureOpenAiApiKey,
  azureApiKey: azureApiKey,
  anthropicApiKey: anthropicApiKey,
  groqApiKey: groqApiKey,
  cohereApiKey: cohereApiKey,
  coApiKey: coApiKey,
  hfToken: hfToken,
  huggingfaceApiKey: huggingfaceApiKey,
  databricksApiKey: databricksApiKey,
  geminiApiKey: geminiApiKey,
  codestralApiKey: codestralApiKey,
  mistralApiKey: mistralApiKey,
  azureAiApiKey: azureAiApiKey,
  nvidiaNimApiKey: nvidiaNimApiKey,
  xaiApiKey: xaiApiKey,
  perplexityaiApiKey: perplexityaiApiKey,
  githubApiKey: githubApiKey,
  deepseekApiKey: deepseekApiKey,

  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION
  }
});
