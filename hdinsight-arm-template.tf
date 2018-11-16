resource "azurerm_resource_group" "hdinsightkafkajb" {
    name                          = "sandbox-hdinsightkafkajb-rg"
    location                      = "East US 2"
    tags {
      Environment                 = "sandbox"
      Terraformed                 = "true"
      Jira_ref                    = ""
  }
}  
  resource "azurerm_template_deployment" "hdinsightkafkajb" {
    name                = "hdinsighttemplate01"
    resource_group_name = "${azurerm_resource_group.hdinsightkafkajb.name}"
  
    template_body = <<DEPLOY
    {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
          "clusterName": {
            "type": "string",
            "metadata": {
              "description": "The name of the Kafka cluster to create. This must be a unique name."
            }
          },
          "clusterLoginUserName": {
            "type": "string",
            "metadata": {
              "description": "These credentials can be used to submit jobs to the cluster and to log into cluster dashboards."
            }
          },
          "clusterLoginPassword": {
            "type": "securestring",
            "metadata": {
              "description": "The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
          },
          "sshUserName": {
            "type": "string",
            "metadata": {
              "description": "These credentials can be used to remotely access the cluster."
            }
          },
          "sshPassword": {
            "type": "securestring",
            "metadata": {
              "description": "The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
          },
          "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
              "description": "Location for all resources."
            }
          }
        },
        "variables": {
          "defaultStorageAccount": {
            "name": "[uniqueString(resourceGroup().id)]",
            "type": "Standard_LRS"
          }
        },
        "resources": [
          {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[variables('defaultStorageAccount').name]",
            "location": "[parameters('location')]",
            "apiVersion": "2017-10-01",
            "sku": {
              "name": "[variables('defaultStorageAccount').type]"
            },
            "kind": "Storage",
            "properties": {}
          },
          {
            "name": "[parameters('clusterName')]",
            "type": "Microsoft.HDInsight/clusters",
            "location": "[parameters('location')]",
            "apiVersion": "2015-03-01-preview",
            "dependsOn": [
              "[concat('Microsoft.Storage/storageAccounts/',variables('defaultStorageAccount').name)]"
            ],
            "tags": {},
            "properties": {
              "clusterVersion": "3.6",
              "osType": "Linux",
              "clusterDefinition": {
                "kind": "kafka",
                "configurations": {
                  "gateway": {
                    "restAuthCredential.isEnabled": true,
                    "restAuthCredential.username": "[parameters('clusterLoginUserName')]",
                    "restAuthCredential.password": "[parameters('clusterLoginPassword')]"
                  }
                }
              },
              "storageProfile": {
                "storageaccounts": [
                  {
                    "name": "[replace(replace(concat(reference(concat('Microsoft.Storage/storageAccounts/', variables('defaultStorageAccount').name), '2017-10-01').primaryEndpoints.blob),'https:',''),'/','')]",
                    "isDefault": true,
                    "container": "[parameters('clusterName')]",
                    "key": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('defaultStorageAccount').name), '2017-10-01').keys[0].value]"
                  }
                ]
              },
              "computeProfile": {
                "roles": [
                  {
                    "name": "headnode",
                    "targetInstanceCount": "2",
                    "hardwareProfile": {
                      "vmSize": "Standard_D3_v2"
                    },
                    "osProfile": {
                      "linuxOperatingSystemProfile": {
                        "username": "[parameters('sshUserName')]",
                        "password": "[parameters('sshPassword')]"
                      }
                    }
                  },
                  {
                    "name": "workernode",
                    "targetInstanceCount": 4,
                    "hardwareProfile": {
                      "vmSize": "Standard_D3_v2"
                    },
                    "dataDisksGroups": [
                      {
                        "disksPerNode": 2
                      }
                    ],
                    "osProfile": {
                      "linuxOperatingSystemProfile": {
                        "username": "[parameters('sshUserName')]",
                        "password": "[parameters('sshPassword')]"
                      }
                    }
                  },
                  {
                    "name": "zookeepernode",
                    "targetInstanceCount": "3",
                    "hardwareProfile": {
                      "vmSize": "Standard_A3"
                    },
                    "osProfile": {
                      "linuxOperatingSystemProfile": {
                        "username": "[parameters('sshUserName')]",
                        "password": "[parameters('sshPassword')]"
                      }
                    }
                  }
                ]
              }
            }
          }
        ],
        "outputs": {
          "cluster": {
            "type": "object",
            "value": "[reference(resourceId('Microsoft.HDInsight/clusters',parameters('clusterName')))]"
          }
        }
      }      
  DEPLOY
  
    parameters {
      "clusterName" = "hdinsightkafkajb"
      "clusterLoginUserName" = "admin"
      "clusterLoginPassword" = "H3lloF01ks10112.3/"
      "sshUserName" = "ssh-admin"
      "sshPassword" = "H3lloF01ks10112.3/"
     }
    deployment_mode = "Incremental"
  } 