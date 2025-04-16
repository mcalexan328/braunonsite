using './main.bicep'

param secureUserName = az.getSecret('87ca812c-85db-47bb-8e25-e57fbeb195ef', 'BraunOnsite', 'braunkey', 'acr-username', 'bfb89e577bd3476bbc525f3a23760fd61a4da80b5')
param securePassword = az.getSecret('87ca812c-85db-47bb-8e25-e57fbeb195ef', 'BraunOnsite', 'braunkey', 'acr-password', '2d2b150991984304a8f4af51a4da80b5')
