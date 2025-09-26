// NU Fridge Backend Extensions
module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/api/tenant/status',
      handler: (req, res) => {
        res.json({
          tenant: 'nufridge',
          name: 'NU Fridge',
          status: 'active',
          architecture: 'multi-image'
        });
      }
    }
  ]
};