# UCR-VRGame-Infraestructure

## Descripción

El repositorio posee la siguiente estructura:

- **README:** Posee las instrucciones que también se mencionan en este documento.
- **Carpeta Templates:** Tiene los archivos de extensión `.json` con [ARM Templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) sobre los servicios que se crean mediante dicho recurso. También se encuentran los archivos nombrados con `Environment-` que poseen las propiedades de los servicios a crear dependiendo el ambiente (Producción, Pruebas...).
- **Archivos de Powershell:** Los scripts de extensión `.ps1` poseen el código ejecutable para crear los servicios de Azure. Cada servicio tiene un archivo por separado, sin embargo, el archivo `CreateResources.ps1` es el archivo principal que ejecuta todos los demás.

### Prerequisitos

1. Debe asegurarse que puede ejecutar comandos de Powershell en su computadora. De no tener la autorización, puede configurarlo al abrir Powershell como administrador y utilizar el siguiente comando. 
```ps
Get-ExecutionPolicy # Para saber su nivel actual
Set-ExecutionPolicy Unrestricted # Cambio temporal para ejecutar scripts
```
> Es importante que al terminar, vuelva a configurar el que tenía anteriormente por motivos de seguridad.

2. Asegúrese de tener [Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli) instalado en su computadora y una cuenta de [Azure](https://portal.azure.com/#home) activa.

3. Instale el [Repositorio de Github](https://github.com/danisala03/UCR-VRGame-Infraestructure) con el código para crear los recursos.

4. Crear un archivo `.json` que tenga el nombre `Environment-{ambiente}`. Reemplace `{ambiente}` por el nombre que desee ponerle a su ambiente (ejemplos Pruebas, Producción...). Este archivo debe definir las siguientes propiedades:

```json
{
    "SubscriptionId": "",
    "ResourceGroupName": "",
    "Location": "<ej: eastus2>",
    "SecondaryLocation": "",

    "WebAppName": "",
    "PythonVersion": "<ej: PYTHON|3.11>",
    "Sku": "",
    "RepoUrl": "",

    "VNetName": "",
    "PublicSubnetName": "",
    "PrivateSubnetName": "",

    "NSGPublicName": "",
    "NSGPrivateName": "",

    "KeyVaultName": "",
    "KeyVaultKey": "",

    "CosmosDBAccountName": "",

    "UserAssignedIdentityName": "",

    "VMSSName": ""
}
```

### Pasos de ejecución

1. Darle permisos a Azure App Actions de poder interactuar con el repositorio. Puede seguir estos pasos para dar dicho permiso: [Configurar Secretos en Github](https://learn.microsoft.com/en-us/azure/app-service/app-service-sql-asp-github-actions?source=recommendations#add-github-secrets-for-your-build).
2. Ejecute el script `./CreateResources.ps1`
3. Se le va a solicitar escribir el ambiente de ejecución. Este ambiente es el que definió anteriormente en el paso 4 de los prerequisitos. Ejemplo: Si nombró al archivo `Environment-Test`, entonces aquí debe escribir `Test`.
4. Esperar a que termine la ejecución y vea los resultados en el [Portal de Azure](https://portal.azure.com/#home).