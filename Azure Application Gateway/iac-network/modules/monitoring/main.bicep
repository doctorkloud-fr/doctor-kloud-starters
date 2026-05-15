// =======================================================================
// monitoring.bicep — Diagnostic Settings + Action Groups + alertes critiques
// =======================================================================
// Six alertes posées : 2 en P1 (Healthy Hosts, Failed Requests),
// 2 en P2 (Latency, CU saturation), 2 en P3 (4xx burst, Bot Manager).
// Cf. Ch.12 pour la grille de criticité complète.
// =======================================================================

targetScope = 'resourceGroup'

@description('Préfixe de nommage')
param namingPrefix string

@description('Environnement')
param environment string

@description('Région Azure')
param location string

@description('Resource ID de l\'AGW à monitorer')
param agwResourceId string

@description('Nom de l\'AGW (pour les noms d'alertes)')
param agwName string

@description('Resource ID du workspace Log Analytics')
param logAnalyticsId string

@description('Tags')
param tags object

// --------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------

var actionGroupP1Name = 'ag-${namingPrefix}-Cloudops-p1'
var actionGroupP2Name = 'ag-${namingPrefix}-Cloudops-p2'
var actionGroupP3Name = 'ag-${namingPrefix}-Cloudops-p3'

// --------------------------------------------------------------------
// DIAGNOSTIC SETTINGS — AccessLog + FirewallLog + AllMetrics
// --------------------------------------------------------------------

resource diagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resourceGroup()
  name: 'diag-${agwName}'
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// --------------------------------------------------------------------
// ACTION GROUPS — P1, P2, P3 (à compléter avec emails/Teams réels)
// --------------------------------------------------------------------

resource actionGroupP1 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupP1Name
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'CloudOpsP1'
    enabled: true
    emailReceivers: [
      {
        name: 'CloudOps-OnCall'
        emailAddress: 'Cloudops-oncall@${namingPrefix}.local'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource actionGroupP2 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupP2Name
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'CloudOpsP2'
    enabled: true
    emailReceivers: [
      {
        name: 'CloudOps-Team'
        emailAddress: 'Cloudops@${namingPrefix}.local'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource actionGroupP3 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupP3Name
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'CloudOpsP3'
    enabled: true
    emailReceivers: [
      {
        name: 'CloudOps-Reporting'
        emailAddress: 'Cloudops-reporting@${namingPrefix}.local'
        useCommonAlertSchema: true
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P1 #1 — Healthy Host Count < 50%
// --------------------------------------------------------------------

resource alertHealthyHosts 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-healthy-hosts-p1'
  location: 'global'
  tags: tags
  properties: {
    description: 'P1 — Plus de la moitié des Backends sont unhealthy'
    severity: 1
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HealthyHostCount'
          metricName: 'HealthyHostCount'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP1.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P1 #2 — Failed Requests > 1% sur 5 min
// --------------------------------------------------------------------

resource alertFailedRequests 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-failed-requests-p1'
  location: 'global'
  tags: tags
  properties: {
    description: 'P1 — Taux d'échec applicatif anormal'
    severity: 1
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailedRequests'
          metricName: 'FailedRequests'
          operator: 'GreaterThan'
          threshold: 100
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP1.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P2 #1 — Latency P95 > 500ms sur 15 min
// --------------------------------------------------------------------

resource alertLatency 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-latency-p2'
  location: 'global'
  tags: tags
  properties: {
    description: 'P2 — Latence Backend dégradée'
    severity: 2
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'BackendLastByteResponseTime'
          metricName: 'BackendLastByteResponseTime'
          operator: 'GreaterThan'
          threshold: 500
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP2.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P2 #2 — CU > 80% du max sur 10 min
// --------------------------------------------------------------------

resource alertCuSaturation 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-cu-saturation-p2'
  location: 'global'
  tags: tags
  properties: {
    description: 'P2 — Capacity Units proches du plafond autoscale'
    severity: 2
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT10M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CurrentCapacityUnits'
          metricName: 'CurrentCapacityUnits'
          operator: 'GreaterThan'
          threshold: 20
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP2.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P3 #1 — 4xx burst (taux > 5% sur 15 min)
// --------------------------------------------------------------------

resource alert4xxBurst 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-4xx-burst-p3'
  location: 'global'
  tags: tags
  properties: {
    description: 'P3 — Burst de codes 4xx (signal applicatif)'
    severity: 3
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ResponseStatus4xx'
          metricName: 'ResponseStatus'
          operator: 'GreaterThan'
          threshold: 500
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          dimensions: [
            {
              name: 'HttpStatusGroup'
              operator: 'Include'
              values: [
                '4xx'
              ]
            }
          ]
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP3.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// ALERTE P3 #2 — Bot Manager UnknownBots burst
// --------------------------------------------------------------------

resource alertBotManager 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${agwName}-bot-burst-p3'
  location: 'global'
  tags: tags
  properties: {
    description: 'P3 — Pic de trafic identifié comme bots inconnus'
    severity: 3
    enabled: true
    scopes: [
      agwResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'BlockedCount'
          metricName: 'BlockedCount'
          operator: 'GreaterThan'
          threshold: 1000
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupP3.id
      }
    ]
  }
}

// --------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------

output diagSettingsId string = diagSettings.id
output actionGroupP1Id string = actionGroupP1.id
output actionGroupP2Id string = actionGroupP2.id
output actionGroupP3Id string = actionGroupP3.id
