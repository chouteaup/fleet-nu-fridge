import React, { useState, useEffect } from 'react'
import { Thermometer, Snowflake, Power, Settings, Wifi, WifiOff } from 'lucide-react'

// Configuration tenant depuis les variables d'environnement
const TENANT = process.env.VITE_TENANT || 'NU'
const TENANT_NAME = process.env.VITE_TENANT_NAME || 'NU Fridge'
const BACKEND_URL = process.env.VITE_BACKEND_URL || 'http://localhost:3001'
const MQTT_URL = process.env.VITE_MQTT_URL || 'ws://localhost:9001'

function App() {
  const [temperature, setTemperature] = useState(4.2)
  const [isConnected, setIsConnected] = useState(false)
  const [compressorOn, setCompressorOn] = useState(true)
  const [targetTemp, setTargetTemp] = useState(4.0)

  // Simulation de la connexion MQTT
  useEffect(() => {
    const interval = setInterval(() => {
      setIsConnected(prev => !prev) // Simulation connexion/déconnexion

      // Simulation variation température
      setTemperature(prev => {
        const variation = (Math.random() - 0.5) * 0.5
        return Math.max(2, Math.min(8, prev + variation))
      })
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  const handleTempChange = (delta) => {
    setTargetTemp(prev => Math.max(2, Math.min(8, prev + delta)))
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 p-4">
      <div className="max-w-md mx-auto">
        {/* Header tenant */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-800">{TENANT_NAME}</h1>
              <p className="text-sm text-gray-600">Simulateur de Réfrigérateur</p>
            </div>
            <div className="flex items-center space-x-2">
              {isConnected ? (
                <Wifi className="w-6 h-6 text-green-500" />
              ) : (
                <WifiOff className="w-6 h-6 text-red-500" />
              )}
              <span className="text-xs text-gray-500">
                {isConnected ? 'Connecté' : 'Déconnecté'}
              </span>
            </div>
          </div>
        </div>

        {/* Température actuelle */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <div className="flex items-center justify-center mb-4">
            <Thermometer className="w-12 h-12 text-blue-500 mr-4" />
            <div className="text-center">
              <div className="text-4xl font-bold text-gray-800">
                {temperature.toFixed(1)}°C
              </div>
              <div className="text-sm text-gray-600">Température actuelle</div>
            </div>
          </div>

          {/* Indicateur de température */}
          <div className="w-full bg-gray-200 rounded-full h-3 mb-4">
            <div
              className={`h-3 rounded-full transition-all duration-500 ${
                temperature <= 5 ? 'bg-blue-500' :
                temperature <= 7 ? 'bg-yellow-500' : 'bg-red-500'
              }`}
              style={{ width: `${Math.min(100, (temperature / 10) * 100)}%` }}
            />
          </div>
        </div>

        {/* Contrôles */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Contrôles</h3>

          {/* Température cible */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Température cible: {targetTemp.toFixed(1)}°C
            </label>
            <div className="flex items-center space-x-4">
              <button
                onClick={() => handleTempChange(-0.5)}
                className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
              >
                -0.5°
              </button>
              <button
                onClick={() => handleTempChange(0.5)}
                className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg"
              >
                +0.5°
              </button>
            </div>
          </div>

          {/* État compresseur */}
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <Snowflake className={`w-6 h-6 mr-2 ${compressorOn ? 'text-blue-500' : 'text-gray-400'}`} />
              <span className="text-gray-700">Compresseur</span>
            </div>
            <button
              onClick={() => setCompressorOn(!compressorOn)}
              className={`flex items-center px-4 py-2 rounded-lg ${
                compressorOn
                  ? 'bg-green-500 hover:bg-green-600 text-white'
                  : 'bg-gray-300 hover:bg-gray-400 text-gray-700'
              }`}
            >
              <Power className="w-4 h-4 mr-2" />
              {compressorOn ? 'ON' : 'OFF'}
            </button>
          </div>
        </div>

        {/* Informations système */}
        <div className="bg-white rounded-lg shadow-lg p-6">
          <div className="flex items-center mb-4">
            <Settings className="w-6 h-6 text-gray-600 mr-2" />
            <h3 className="text-lg font-semibold text-gray-800">Configuration</h3>
          </div>

          <div className="space-y-2 text-sm text-gray-600">
            <div className="flex justify-between">
              <span>Tenant:</span>
              <span className="font-medium">{TENANT}</span>
            </div>
            <div className="flex justify-between">
              <span>Port:</span>
              <span className="font-medium">5174</span>
            </div>
            <div className="flex justify-between">
              <span>Backend:</span>
              <span className="font-medium text-xs">{BACKEND_URL}</span>
            </div>
            <div className="flex justify-between">
              <span>MQTT:</span>
              <span className="font-medium text-xs">{MQTT_URL}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App