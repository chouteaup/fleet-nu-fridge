import { useState, useEffect } from 'react'
import { Thermometer, Snowflake, Zap, AlertTriangle, TrendingUp } from 'lucide-react'

function NUFridgeDashboard() {
  const [fridgeData, setFridgeData] = useState({
    temperature: -2.5,
    humidity: 45,
    powerConsumption: 185,
    status: 'normal',
    items: [
      { name: 'Yaourts Nature', quantity: 24, expiry: '2025-10-15', category: 'dairy' },
      { name: 'Compotes Pomme', quantity: 18, expiry: '2025-11-20', category: 'fruits' },
      { name: 'Eau Minérale', quantity: 36, expiry: '2026-03-10', category: 'beverages' },
      { name: 'Sandwichs Jambon', quantity: 8, expiry: '2025-09-28', category: 'prepared' },
    ],
    alerts: [
      { id: 1, type: 'warning', message: 'Température légèrement élevée détectée', time: '10:30' },
      { id: 2, type: 'info', message: 'Réapprovisionnement Yaourts prévu demain', time: '09:15' }
    ]
  })

  const [loading, setLoading] = useState(false)

  useEffect(() => {
    // Simuler la mise à jour des données en temps réel
    const interval = setInterval(() => {
      setFridgeData(prev => ({
        ...prev,
        temperature: (Math.random() * 2 - 3).toFixed(1), // Entre -5°C et -1°C
        powerConsumption: Math.floor(Math.random() * 50) + 160, // Entre 160W et 210W
        humidity: Math.floor(Math.random() * 20) + 40 // Entre 40% et 60%
      }))
    }, 10000) // Update every 10 seconds

    return () => clearInterval(interval)
  }, [])

  const getStatusColor = (status) => {
    switch (status) {
      case 'normal': return 'text-green-400'
      case 'warning': return 'text-yellow-400'
      case 'critical': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getCategoryColor = (category) => {
    switch (category) {
      case 'dairy': return 'bg-blue-500'
      case 'fruits': return 'bg-orange-500'
      case 'beverages': return 'bg-cyan-500'
      case 'prepared': return 'bg-purple-500'
      default: return 'bg-gray-500'
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 to-slate-900 p-6">
      {/* Header NU Fridge */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2 flex items-center gap-3">
          <Snowflake className="w-10 h-10 text-cyan-400" />
          NU Fridge Smart Kiosk
        </h1>
        <p className="text-cyan-200 text-lg">Gestion intelligente de votre frigo connecté</p>
      </div>

      {/* Statistiques principales */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-slate-800/50 backdrop-blur-sm border border-cyan-500/20 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-cyan-400 font-medium">Température</p>
              <p className="text-2xl font-bold text-white">{fridgeData.temperature}°C</p>
              <p className={`text-sm ${getStatusColor(fridgeData.status)}`}>
                {fridgeData.status === 'normal' ? 'Optimal' : 'Attention'}
              </p>
            </div>
            <Thermometer className="w-8 h-8 text-cyan-400" />
          </div>
        </div>

        <div className="bg-slate-800/50 backdrop-blur-sm border border-blue-500/20 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-400 font-medium">Humidité</p>
              <p className="text-2xl font-bold text-white">{fridgeData.humidity}%</p>
              <p className="text-sm text-green-400">Normal</p>
            </div>
            <div className="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
              <div className="w-4 h-4 rounded-full bg-blue-400"></div>
            </div>
          </div>
        </div>

        <div className="bg-slate-800/50 backdrop-blur-sm border border-yellow-500/20 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-yellow-400 font-medium">Consommation</p>
              <p className="text-2xl font-bold text-white">{fridgeData.powerConsumption}W</p>
              <p className="text-sm text-yellow-400">En cours</p>
            </div>
            <Zap className="w-8 h-8 text-yellow-400" />
          </div>
        </div>

        <div className="bg-slate-800/50 backdrop-blur-sm border border-green-500/20 rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-400 font-medium">Articles</p>
              <p className="text-2xl font-bold text-white">{fridgeData.items.reduce((sum, item) => sum + item.quantity, 0)}</p>
              <p className="text-sm text-green-400">Total stock</p>
            </div>
            <TrendingUp className="w-8 h-8 text-green-400" />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Inventaire */}
        <div className="bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-cyan-400"></div>
            Inventaire Produits
          </h2>
          <div className="space-y-4">
            {fridgeData.items.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-4 bg-slate-700/30 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className={`w-3 h-3 rounded-full ${getCategoryColor(item.category)}`}></div>
                  <div>
                    <h3 className="font-medium text-white">{item.name}</h3>
                    <p className="text-sm text-slate-400">Expire le {item.expiry}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-white">{item.quantity}</p>
                  <p className="text-xs text-slate-500">unités</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Alertes et Notifications */}
        <div className="bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-orange-400" />
            Alertes & Notifications
          </h2>
          <div className="space-y-4">
            {fridgeData.alerts.map((alert) => (
              <div key={alert.id} className={`p-4 rounded-lg border-l-4 ${
                alert.type === 'warning' ? 'bg-orange-500/10 border-orange-500' : 'bg-blue-500/10 border-blue-500'
              }`}>
                <div className="flex items-start justify-between">
                  <p className="text-white text-sm">{alert.message}</p>
                  <span className="text-xs text-slate-400">{alert.time}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-6 p-4 bg-gradient-to-r from-cyan-500/10 to-blue-500/10 rounded-lg border border-cyan-500/20">
            <h3 className="text-cyan-400 font-medium mb-2">État Système</h3>
            <p className="text-sm text-white">Tous les systèmes fonctionnent normalement</p>
            <p className="text-xs text-slate-400 mt-1">Dernière vérification: il y a 2 minutes</p>
          </div>
        </div>
      </div>

      {/* Footer NU */}
      <div className="mt-8 text-center">
        <p className="text-slate-500 text-sm">
          NU Fridge Smart Kiosk - Powered by Fleet IoT Platform
        </p>
      </div>
    </div>
  )
}

export default NUFridgeDashboard