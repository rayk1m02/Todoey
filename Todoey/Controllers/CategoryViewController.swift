//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Raymond Kim on 6/14/24.
//  Copyright © 2024 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
//import SwipeCellKit
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    
    var categories: Results<Category>?
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewWillAppear(_ animated: Bool) {
        guard let navBar = navigationController?.navigationBar else { fatalError("DNE") }
        navBar.backgroundColor = UIColor(hexString: "1D9BF6")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        tableView.separatorStyle = .none
    }
    
    //MARK: - TableView Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // tap into the super class (SwipeTableViewController) and at the indexPath
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let category = categories?[indexPath.row] {
            cell.textLabel?.text = category.name
            guard let categoryColor = UIColor(hexString: category.color) else { fatalError() }
            cell.backgroundColor = categoryColor
            cell.textLabel?.textColor = ContrastColorOf(categoryColor, returnFlat: true)
        }
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ToDoListViewController
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categories?[indexPath.row]
        }
    }
    
    //MARK: - Data Manipulation Methods
    
    func save(category: Category) {
        do { try realm.write { realm.add(category) } }
        catch { print("Error saving categoy \(error)") }
        tableView.reloadData()
    }
    
    func loadCategories() {
//        let request: NSFetchRequest<Category> = Category.fetchRequest()
//        do { categories = try context.fetch(request) }
//        catch { print("Error loading categories \(error)") }
//        tableView.reloadData()
        categories = realm.objects(Category.self)
        tableView.reloadData()
    }
    
    //MARK: - Delete Data From Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        if let categoryForDeletion = self.categories?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(categoryForDeletion)
                }
            } catch {
                print("Error deleting category, \(error)")
            }
        }
    }
    
    
    //MARK: - Add New Categories
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Add a new category"
            textField = alertTextField
        }
        // need var textField to hold the alert textfield so that it can be referenced from action closure
        let action = UIAlertAction(title: "Add", style: .default) { action in
            let newCategory = Category()
            newCategory.name = textField.text!
            newCategory.color = UIColor.randomFlat().hexValue()
            self.save(category: newCategory)
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
}
